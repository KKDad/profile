# Entry point for bash. ~/.bashrc is a stub written by install.sh that sets PROFILE_DIR and
# PROFILE_HOST, then sources this file.

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

: "${PROFILE_DIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"

# History
###############################################################
HISTCONTROL=ignoreboth
shopt -s histappend
HISTSIZE=1000
HISTFILESIZE=2000
shopt -s checkwinsize

[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# Colors and prompt
###############################################################
source "$PROFILE_DIR/shell/bash/colors.sh"
source "$PROFILE_DIR/shell/bash/prompt.sh"

if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

for module in env ssh-agent git java profile; do
  source "$PROFILE_DIR/shell/common/$module.sh"
done
unset module

[ -f "$PROFILE_DIR/shell/hosts/$PROFILE_HOST.bash" ] && source "$PROFILE_DIR/shell/hosts/$PROFILE_HOST.bash"
