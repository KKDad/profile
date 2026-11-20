#!/usr/bin/env python3
import argparse
import glob
import json
import os
import subprocess
import sys
import time
import uuid
from dataclasses import dataclass
from datetime import datetime

BUSY_STATUSES = {"working", "blocked"}
EXIT_DIALOG_MARKER = "Background work is running"
HOUSEKEEPING_PREFIXES = ("<local-command", "<command-name>", "<command-message>")
CC_DIRECTORY = os.path.expanduser("~/git")
OPEX_DIRECTORY = os.path.expanduser("~/git/pcl-ai-tools")
CLAUDE_PROJECTS_GLOB = os.path.expanduser("~/.claude/projects/*/{session_id}.jsonl")
EXIT_TIMEOUT_SECONDS = 15
SHELL_SETTLE_SECONDS = 1.0
TAIL_BLOCK_BYTES = 64 * 1024


@dataclass(frozen=True)
class Plan:
    pane_id: str
    cwd: str
    session_id: str
    launcher: str
    age_minutes: float
    skip_reason: str
    resume: bool


def herdr(*args, check=True):
    completed = subprocess.run(["herdr", *args], capture_output=True, text=True)
    if check and completed.returncode != 0:
        raise RuntimeError(f"herdr {' '.join(args)} failed: {completed.stderr.strip() or completed.stdout.strip()}")
    return completed


def herdr_json(*args):
    return json.loads(herdr(*args).stdout)["result"]


def list_claude_panes(workspaces):
    panes = herdr_json("pane", "list")["panes"]
    return [
        pane for pane in panes
        if pane.get("agent") == "claude" and (not workspaces or pane["workspace_id"] in workspaces)
    ]


def invoking_pane_id():
    completed = herdr("pane", "current", check=False)
    if completed.returncode != 0:
        return None
    return json.loads(completed.stdout)["result"]["pane"]["pane_id"]


def session_id_of(pane):
    value = (pane.get("agent_session") or {}).get("value")
    try:
        return str(uuid.UUID(value))
    except (ValueError, AttributeError, TypeError):
        return None


def reversed_lines(path, block_size=TAIL_BLOCK_BYTES):
    with open(path, "rb") as session_file:
        position = session_file.seek(0, os.SEEK_END)
        remainder = b""
        while position > 0:
            read_size = min(block_size, position)
            position -= read_size
            session_file.seek(position)
            lines = (session_file.read(read_size) + remainder).split(b"\n")
            remainder = lines[0]
            yield from reversed(lines[1:])
        yield remainder


def is_conversation_entry(entry):
    if entry.get("type") not in ("user", "assistant") or entry.get("isMeta") or not entry.get("timestamp"):
        return False
    content = (entry.get("message") or {}).get("content")
    if isinstance(content, list):
        content = next((block.get("text") for block in content if isinstance(block, dict) and block.get("type") == "text"), "")
    return not (content or "").lstrip().startswith(HOUSEKEEPING_PREFIXES)


def last_activity_epoch(path):
    for line in reversed_lines(path):
        try:
            entry = json.loads(line)
        except ValueError:
            continue
        if is_conversation_entry(entry):
            return datetime.fromisoformat(entry["timestamp"].replace("Z", "+00:00")).timestamp()
    print(f"warning: no conversation entries in {path}", file=sys.stderr)
    return None


def session_age_minutes(session_id):
    if not session_id:
        return None
    matches = glob.glob(CLAUDE_PROJECTS_GLOB.format(session_id=session_id))
    activity = [epoch for epoch in map(last_activity_epoch, matches) if epoch is not None]
    if not activity:
        return None
    return (time.time() - max(activity)) / 60


def is_claude_running(pane_id):
    return herdr_json("pane", "get", pane_id)["pane"].get("agent") == "claude"


def is_waiting_on_exit_dialog(pane_id):
    return EXIT_DIALOG_MARKER in herdr("pane", "read", pane_id).stdout


def answer_exit_dialog(pane_id, stop_background):
    keys = ["enter"] if stop_background else ["down", "enter"]
    herdr("pane", "send-keys", pane_id, *keys)


def exit_claude(pane_id, stop_background):
    herdr("pane", "send-keys", pane_id, "esc")
    herdr("pane", "run", pane_id, "/exit")
    deadline = time.time() + EXIT_TIMEOUT_SECONDS
    dialog_answered = False
    while time.time() < deadline:
        if not is_claude_running(pane_id):
            return True
        if not dialog_answered and is_waiting_on_exit_dialog(pane_id):
            answer_exit_dialog(pane_id, stop_background)
            dialog_answered = True
        time.sleep(0.5)
    herdr("pane", "send-keys", pane_id, "ctrl+c")
    herdr("pane", "send-keys", pane_id, "ctrl+c")
    time.sleep(2)
    return not is_claude_running(pane_id)


def reload_shell(pane_id):
    time.sleep(SHELL_SETTLE_SECONDS)
    herdr("pane", "run", pane_id, "reload")
    time.sleep(SHELL_SETTLE_SECONDS)


def launcher_for(cwd):
    resolved = os.path.realpath(cwd or "")
    if resolved == os.path.realpath(OPEX_DIRECTORY):
        return "opex"
    if resolved == os.path.realpath(CC_DIRECTORY):
        return "cc"
    return "claude"


def format_age(age_minutes):
    if age_minutes is None:
        return "unknown age"
    minutes = round(age_minutes)
    return f"age {minutes}m" if minutes < 60 else f"age {minutes // 60}h"


def plan_pane(pane, args):
    session_id = session_id_of(pane)
    age = session_age_minutes(session_id)
    busy = pane.get("agent_status") in BUSY_STATUSES and not args.force
    return Plan(
        pane_id=pane["pane_id"],
        cwd=pane.get("cwd"),
        session_id=session_id,
        launcher=launcher_for(pane.get("cwd")),
        age_minutes=age,
        skip_reason=f"{pane['agent_status']}, use --force" if busy else None,
        resume=not args.no_resume and age is not None and age < args.max_age,
    )


def describe(plan, no_resume):
    actions = ["exit", "reload"] + ([f"resume via {plan.launcher}"] if plan.resume else [])
    outcome = f"{', '.join(actions)} ({format_age(plan.age_minutes)})"
    if not plan.resume and not no_resume:
        outcome += ", not resumed" if plan.age_minutes is not None else ", not resumed: no session activity found"
    return outcome


def execute(plan, args):
    if not exit_claude(plan.pane_id, stop_background=not args.keep_background):
        return f"{plan.pane_id} FAILED: claude still running after {EXIT_TIMEOUT_SECONDS}s", False
    reload_shell(plan.pane_id)
    if plan.resume:
        herdr("pane", "run", plan.pane_id, f"{plan.launcher} --resume {plan.session_id}")
    return f"{plan.pane_id} {describe(plan, args.no_resume)}", True


def process_pane(pane, args):
    plan = plan_pane(pane, args)
    prefix = "[dry-run] " if args.dry_run else ""
    if plan.skip_reason:
        return f"{prefix}{plan.pane_id} skipped ({plan.skip_reason})", True
    if args.dry_run:
        return f"{prefix}{plan.pane_id} would {describe(plan, args.no_resume)} cwd={plan.cwd}", True
    return execute(plan, args)


def parse_args():
    parser = argparse.ArgumentParser(description="Exit Claude in every herdr pane, reload zsh, resume recent sessions.")
    parser.add_argument("--dry-run", action="store_true", help="print the plan, change nothing")
    parser.add_argument("--no-resume", action="store_true", help="leave every pane at a shell prompt")
    parser.add_argument("--max-age", type=int, default=60, metavar="MIN", help="resume only sessions newer than this (default 60)")
    parser.add_argument(
        "--keep-background", action="store_true",
        help="at the 'Background work is running' dialog pick 'Move to background and exit' (default: exit and stop tasks)",
    )
    parser.add_argument("--force", action="store_true", help="also exit panes that are working or blocked")
    parser.add_argument("--workspace", action="append", default=[], metavar="ID", help="limit to a workspace id (repeatable)")
    return parser.parse_args()


def main():
    args = parse_args()
    own_pane_id = invoking_pane_id()
    panes = list_claude_panes(set(args.workspace))
    targets = [pane for pane in panes if pane["pane_id"] != own_pane_id]
    own_pane = next((pane for pane in panes if pane["pane_id"] == own_pane_id), None)

    print(f"{len(targets)} claude pane(s) to process, invoking pane: {own_pane_id or 'unknown'}")
    all_succeeded = True
    for pane in sorted(targets, key=lambda candidate: candidate["pane_id"]):
        try:
            line, succeeded = process_pane(pane, args)
        except RuntimeError as error:
            line, succeeded = f"{pane['pane_id']} FAILED: {error}", False
        all_succeeded = all_succeeded and succeeded
        print(line)

    if own_pane is not None:
        print(f"{own_pane_id} left running (this session). Run `reload` here yourself, then restart claude if needed.")
    return 0 if all_succeeded else 1


if __name__ == "__main__":
    sys.exit(main())
