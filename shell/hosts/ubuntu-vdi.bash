# Ubuntu dev box (personal). Loaded last by shell/bash/init.bash.

alias ls='ls --color=auto'
alias grep='grep --color=auto'
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias cc='cd ~/git && clear && claude --permission-mode auto'

# Podman as the docker CLI
alias docker=podman

if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# Update Path
###############################################################
path_prepend "$HOME/.local/bin"
export PATH
