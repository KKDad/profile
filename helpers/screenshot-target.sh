#!/usr/bin/env bash
#
# screenshot-target.sh - flip the macOS screenshot destination (cmd-shift-3/4/5)
#
# macOS stores this in com.apple.screencapture:
#   target   = clipboard | file | preview | mail | messages
#   location = directory used when target=file
#
# The Screenshot.app "Options > Save to" menu writes the same keys, so this
# script and the UI stay in sync.
#
# Usage:
#   screenshot-target.sh                 # -> clipboard (default)
#   screenshot-target.sh clipboard
#   screenshot-target.sh desktop         # -> file, ~/Desktop
#   screenshot-target.sh file [DIR]      # -> file, DIR (default ~/Desktop)
#   screenshot-target.sh status
#   screenshot-target.sh toggle          # clipboard <-> desktop
#
set -euo pipefail

DOMAIN="com.apple.screencapture"

current_target() {
  defaults read "$DOMAIN" target 2>/dev/null || echo "file"
}

current_location() {
  defaults read "$DOMAIN" location 2>/dev/null || echo "$HOME/Desktop (default)"
}

apply() {
  # Screenshot UI / SystemUIServer caches these on launch.
  killall SystemUIServer 2>/dev/null || true
}

show_status() {
  printf 'screenshot target:   %s\n' "$(current_target)"
  printf 'screenshot location: %s\n' "$(current_location)"
}

set_clipboard() {
  defaults write "$DOMAIN" target clipboard
  apply
  echo "Screenshots -> clipboard."
}

set_file() {
  local dir="${1:-$HOME/Desktop}"
  dir="${dir/#\~/$HOME}"
  if [[ ! -d "$dir" ]]; then
    echo "Not a directory: $dir" >&2
    exit 1
  fi
  defaults write "$DOMAIN" target file
  defaults write "$DOMAIN" location "$dir"
  apply
  printf 'Screenshots -> files in %s\n' "$dir"
}

case "${1:-clipboard}" in
  clipboard|clip|cb)
    set_clipboard
    ;;
  desktop)
    set_file "$HOME/Desktop"
    ;;
  file|dir)
    set_file "${2:-$HOME/Desktop}"
    ;;
  toggle)
    if [[ "$(current_target)" == "clipboard" ]]; then
      set_file "$HOME/Desktop"
    else
      set_clipboard
    fi
    ;;
  status|show)
    show_status
    ;;
  -h|--help|help)
    sed -n '2,20p' "$0"
    ;;
  *)
    echo "Unknown argument: $1 (try: clipboard | desktop | file DIR | toggle | status)" >&2
    exit 1
    ;;
esac
