autoload -Uz compinit && compinit

alias ls='ls --color'
alias ll='ls -al --color'
alias kcdb='kubectl --context=agilbert port-forward postgres-0 5432:5432'

alias explorer=open

# Add psql and libraries to path
export PATH="/opt/homebrew/opt/libpq/bin:$PATH"

# Alias for Telepresence & cleanup
###############################################################
alias tele='docker run -it -v $HOME:/home -p 5005:5005 --privileged docker-upgrade.artifactory.build.upgrade.com/telepresence:latest'
alias clean='yes | docker system prune'


# For dealing with Maven 
###############################################################
function getVersion() {
  local verbose=$1
  if [[ "$verbose" == "-v" ]]; then 
    echo "mvn org.apache.maven.plugins:maven-help-plugin:2.1.1:evaluate -Dexpression=project.version"
    mvn org.apache.maven.plugins:maven-help-plugin:2.1.1:evaluate -Dexpression=project.version
  else
    echo "mvn org.apache.maven.plugins:maven-help-plugin:2.1.1:evaluate -Dexpression=project.version | grep -v '[INFO]'"
    mvn org.apache.maven.plugins:maven-help-plugin:2.1.1:evaluate -Dexpression=project.version | grep -v '[INFO]'
  fi
}

function setVersion() {
  local v=$1
  cat pom.xml | mvn org.codehaus.mojo:versions-maven-plugin:2.7:set -DgenerateBackupPoms=false -DprocessAllModules -DnewVersion=${v}
}
alias fastinstall='mvn clean install -DskipTests=True -Dskip.unit.tests=True -Dskip.integration.tests=True -Dspotbugs.skip -Dassembly.skipAssembly=true -T 10'



# Kubectl commands can be very slow because of Sophos
###############################################################
#diskutil erasevolume HFS+ 'ram_disk' `hdiutil attach -nomount ram://262144`

alias k='kubectl --cache-dir /Volumes/ram_disk/kube_cache'

# Run ssh-agent, if it's not already running
SSH_PID_COUNT=`pgrep ssh-agent | wc -l | awk '{$1=$1};1'`
if [ "$SSH_PID_COUNT" = "0" ]; then 
   eval "$(ssh-agent -s)"
fi

# Include a new prompt with Git support
source ~agilbert/kkdad/profile/env/zsh/prompt.sh


export PATH="${PATH}:/Applications/Visual Studio Code.app/Contents/Resources/app/bin"
export JAVA_HOME=`/usr/libexec/java_home`

# Fix git/gpg signing error: Inappropriate ioctl for device
export GPG_TTY=$(tty)


# Fix an annoying docker warning
docker() {
 if [[ `uname -m` == "arm64" ]] && [[ "$1" == "run" || "$1" == "build" ]]; then
    /usr/local/bin/docker "$1" --platform linux/amd64 "${@:2}"
  else
     /usr/local/bin/docker "$@"
  fi
}

# Run spectrum eod
eod()
{
  echo "kubectl exec -it deployment/spectrum -- /bin/sh /docker-entrypoint.sh eod 1234 ACTIVE"
  kubectl exec -it deployment/spectrum -- /bin/sh /docker-entrypoint.sh eod 1234 ACTIVE
}


update()
{
  vi ~/.zshrc
  source ~/.zshrc
  cp ~/.zshrc ~/kkdad/profile/env/zsh/dot.zshrc
  pushd ~/kkdad/profile
    git commit -a
    git push
  popd	
}

rebase() 
{
   set -x
   CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
   git checkout master
   git fetch -p
   git pull
   git checkout $CURRENT_BRANCH
   git rebase master
   set +x
}

killzeros() 
{
  set -x
  kubectl get pods | grep 0/ | awk '{print$1}' | xargs kubectl delete pod
  set +x
}
