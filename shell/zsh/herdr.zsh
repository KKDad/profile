# List every herdr zsh pane in the Agents panel: "zsh" (idle) at the prompt, the command (working) while it runs.
#
# herdr clears custom agent labels about a second after the shell is idle (herdr src/pane.rs, self-reported
# agents), so the pane reports as the built-in "amp" and shows its own text via --display-agent. amp has no
# special handling in herdr beyond a per-agent sound switch; mute it with [ui.sound.agents] amp = "off".
# Real agents are released to herdr's own detection.

[[ "$HERDR_ENV" == 1 ]] && (( $+commands[herdr] )) || return 0

renameWorkspace() {
  (( $# )) || { print -u2 "usage: renameWorkspace <new name>"; return 1; }
  herdr workspace rename "$HERDR_WORKSPACE_ID" "$*" >/dev/null && print "Workspace renamed to: $*"
}

zmodload zsh/datetime
autoload -Uz add-zsh-hook

typeset -g _herdr_pane_id="$HERDR_PANE_ID"
if [[ -z "$_herdr_pane_id" ]]; then
  [[ "$(herdr pane current --current 2>/dev/null)" =~ '"pane_id":"([^"]+)"' ]] && _herdr_pane_id="$match[1]"
fi
[[ -n "$_herdr_pane_id" ]] || return 0

typeset -g _herdr_source=zsh
typeset -g _herdr_agent=amp

typeset -ga HERDR_AGENT_COMMANDS
(( ${#HERDR_AGENT_COMMANDS} )) || HERDR_AGENT_COMMANDS=(
  pi claude claude-code codex gemini cursor cursor-agent devin devin-cli agy antigravity
  antigravity-cli cline omp mastracode opencode copilot ghcs kimi kimi-code kiro kiro-cli
  droid amp grok hermes kilo qodercli qoder qwen qwen-code letta letta-code maki muse
)

# herdr drops a report whose seq is not above the last one for this pane and source,
# and that memory outlives the shell, so use wall-clock microseconds.
_herdr_seq() {
  REPLY=$(( EPOCHREALTIME * 1000000 ))
  REPLY=${REPLY%.*}
}

# Wrapper options that take a separate value are skipped with it, so "sudo -u root vi" reports vi, not root.
_herdr_program() {
  local word wrapper= skip_value=
  for word in ${(z)1}; do
    if [[ -n "$skip_value" ]]; then
      skip_value=
      continue
    fi
    case "$word" in
      *=*|<->) continue ;;
      -*)
        case "$wrapper:$word" in
          sudo:-[ugCDhprtU]|sudo:--(user|group|chdir|host|prompt|role|type|other-user|close-from)) skip_value=1 ;;
          doas:-[uC]|nice:-n|env:-[uCS]|exec:-a|time:-[fo]) skip_value=1 ;;
        esac
        continue ;;
      sudo|doas|command|builtin|exec|nohup|time|nice|env|caffeinate|noglob|nocorrect) wrapper="$word"; continue ;;
      *) REPLY="${word:t}"; return 0 ;;
    esac
  done
  return 1
}

# The caller takes the seq, so a backgrounded idle report can never outrank the next working report.
_herdr_report() {
  local seq="$1" state="$2" display="$3" message="$4"
  herdr pane report-agent "$_herdr_pane_id" --source "$_herdr_source" --agent "$_herdr_agent" \
    --state "$state" --message "$message" --seq $seq >/dev/null 2>&1
  herdr pane report-metadata "$_herdr_pane_id" --source "$_herdr_source" --agent "$_herdr_agent" \
    --display-agent "$display" --seq $(( seq + 1 )) >/dev/null 2>&1
}

_herdr_release() {
  local REPLY
  _herdr_seq
  herdr pane release-agent "$_herdr_pane_id" --source "$_herdr_source" --agent "$_herdr_agent" \
    --seq $REPLY >/dev/null 2>&1
}

_herdr_preexec() {
  local cmd="${2:-$1}" REPLY
  _herdr_program "$cmd" || return 0
  if (( ${HERDR_AGENT_COMMANDS[(Ie)$REPLY]} )); then
    _herdr_release
    return 0
  fi
  local program="$REPLY"
  _herdr_seq
  # Synchronous on purpose: the row must say "working" before the command takes the terminal.
  _herdr_report $REPLY working "$program" "${cmd[1,200]}"
  return 0
}

_herdr_precmd() {
  local REPLY
  _herdr_seq
  _herdr_report $REPLY idle zsh "" &!
}

add-zsh-hook preexec _herdr_preexec
add-zsh-hook precmd _herdr_precmd
add-zsh-hook zshexit _herdr_release
