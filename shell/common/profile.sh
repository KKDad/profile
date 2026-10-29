# Working with this repo. The rc files in $HOME are stubs written by install.sh, so the
# repo is the only copy: edit here, then reload. Nothing is ever copied back.

# Re-source the shell config and re-read tmux in any running server
reload() {
  if [ -n "$ZSH_VERSION" ]; then
    source ~/.zshrc
  else
    source ~/.bashrc
  fi

  if command -v tmux &> /dev/null && tmux has-session 2> /dev/null && [ -f ~/.tmux.conf ]; then
    tmux source-file ~/.tmux.conf && echo "Reloaded running tmux server"
  fi
}
alias refreshZsh=reload

# dotfiles        cd into the repo
# dotfiles pull   fast-forward from origin, then reload
# dotfiles push   commit everything (opens the editor) and push
dotfiles() {
  case "$1" in
    "")
      cd "$PROFILE_DIR"
      ;;
    pull)
      git -C "$PROFILE_DIR" pull --ff-only && reload
      ;;
    push)
      git -C "$PROFILE_DIR" commit -a && git -C "$PROFILE_DIR" push
      ;;
    *)
      echo "Usage: dotfiles [pull|push]"
      return 1
      ;;
  esac
}
