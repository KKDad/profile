# Ubuntu dev box (personal). Loaded last by shell/zsh/init.zsh.

# Aliases
###############################################################
alias ls='ls --color=auto'
alias grep='grep --color=auto'
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias cc='cd ~/git && clear && claude --permission-mode auto'

# Podman as the docker CLI
alias docker=podman

[ -f ~/.bash_aliases ] && source ~/.bash_aliases

# Update Path
###############################################################
path_prepend "$HOME/.local/bin"
