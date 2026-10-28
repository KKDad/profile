test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"

# Reset iTerm2 tab title when Claude leaves it in a wrong state
resettab() {
  echo -ne "\033]0;\007"
}

function update_iterm2_badge_and_title() {
  local repo=""
  local cwd_name=$(basename "$PWD")

  # Get Git repo name if inside one
  if command -v git &> /dev/null && git rev-parse --is-inside-work-tree &> /dev/null; then
    repo=$(basename "$(git rev-parse --show-toplevel)")
  fi

  # Set badge to repo name (or blank)
  if [[ -n "$repo" ]]; then
    printf "\033]1337;SetBadgeFormat=%s\a" "$(echo -n "$repo" | base64)"
  else
    printf "\033]1337;SetBadgeFormat=%s\a" "$(echo -n "" | base64)"
  fi

  # Set tab/window title (showing folder name or repo)
  local title=""
  if [[ -n "$repo" ]]; then
    title="$repo — $cwd_name"
  else
    title="$cwd_name"
  fi
  echo -ne "\033]0;${title}\007"
}

# Run before each prompt
add-zsh-hook precmd update_iterm2_badge_and_title
