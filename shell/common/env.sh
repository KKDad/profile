# Environment shared by every host. Sourced by zsh and bash.

path_prepend() {
  case ":$PATH:" in
    *":$1:"*) ;;
    *) PATH="$1:$PATH" ;;
  esac
}

path_append() {
  case ":$PATH:" in
    *":$1:"*) ;;
    *) PATH="$PATH:$1" ;;
  esac
}

path_append "$PROFILE_DIR/bin"
export PATH

# Fix git/gpg signing error: Inappropriate ioctl for device
export GPG_TTY=$(tty)

export COLUMNS="120"

# nvm: Homebrew install on macOS, upstream install script on Linux
###############################################################
export NVM_DIR="$HOME/.nvm"
if [ -s "/opt/homebrew/opt/nvm/nvm.sh" ]; then
  . "/opt/homebrew/opt/nvm/nvm.sh"
  [ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && . "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"
elif [ -s "$NVM_DIR/nvm.sh" ]; then
  . "$NVM_DIR/nvm.sh"
  [ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"
fi

# pyenv for controlling python versions
###############################################################
export PYENV_ROOT="$HOME/.pyenv"
[ -d "$PYENV_ROOT/bin" ] && path_prepend "$PYENV_ROOT/bin"
command -v pyenv > /dev/null 2>&1 && eval "$(pyenv init -)"
