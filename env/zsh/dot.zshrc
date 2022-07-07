autoload -Uz compinit && compinit

alias ls='ls --color'
alias ll='ls -al --color'
alias kcdb='kubectl --context=agilbert port-forward postgres-0 5432:5432'

alias explorer=open
alias tele='docker run -it -v $HOME:/home -p 5005:5005 --privileged docker-upgrade.artifactory.build.upgrade.com/telepresence:latest'
alias clean='yes | docker system prune'

# Kubectl commands can be very slow because of Sophos
#diskutil erasevolume HFS+ 'ram_disk' `hdiutil attach -nomount ram://262144`

alias k='kubectl --cache-dir /Volumes/ram_disk/kube_cache'

# Run ssh-agent, if it's not already running
SSH_PID_COUNT=`pgrep ssh-agent | wc -l | awk '{$1=$1};1'`
if [ "$SSH_PID_COUNT" = "0" ]; then 
   eval "$(ssh-agent -s)"
fi

source ~agilbert/kkdad/profile/env/zsh/prompt.sh

export PATH="${PATH}:/Applications/Visual Studio Code.app/Contents/Resources/app/bin"

export JAVA_HOME=`/usr/libexec/java_home`
