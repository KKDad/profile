autoload -Uz compinit && compinit

alias ll='ls -al --color'
alias kcdb='kubectl --context=agilbert port-forward postgres-0 5432:5432'

# Kubectl commands can be very slow because of Sophos
#diskutil erasevolume HFS+ 'ram_disk' `hdiutil attach -nomount ram://262144`

alias k='kubectl --cache-dir /Volumes/ram_disk/kube_cache'

# Run ssh-agent, if it's not already running
SSH_PID_COUNT=`pgrep ssh-agent | wc -l | awk '{$1=$1};1'`
if [ "$SSH_PID_COUNT" = "0" ]; then 
   eval "$(ssh-agent -s)"
fi

source ~/kkdad/profile/env/zsh/prompt.sh
