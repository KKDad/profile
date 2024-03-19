autoload -Uz compinit && compinit

# Aliases
###############################################################
alias ls='ls --color'
alias ll='ls -al --color'
alias kcdb='kubectl --context=agilbert port-forward postgres-0 5432:5432'
alias kcdbs='kubectl port-forward service/spectrum-db 1433:1433'
alias grc='git rebase --continue'


alias kclss='klog creditline-servicing-srvc'
alias kclsm='klog creditline-servicing-srvc'
alias klac='klog loan-app-creation-srvc'

alias explorer=open


# Update Path
###############################################################
export PATH="/opt/homebrew/opt/libpq/bin:$PATH"
export PATH="${PATH}:/Applications/Visual Studio Code.app/Contents/Resources/app/bin"
export JAVA_HOME=`/usr/libexec/java_home`

export NVM_DIR="$HOME/.nvm"
[ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"  # This loads nvm
[ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"  # This loads nvm bash_completion


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


# Run ssh-agent, if it's not already running
###############################################################
SSH_PID_COUNT=`pgrep ssh-agent | wc -l | awk '{$1=$1};1'`
if [ "$SSH_PID_COUNT" = "0" ]; then 
   eval "$(ssh-agent -s)"
fi


# Include a new prompt with Git support
source ~agilbert/kkdad/profile/env/zsh/prompt.sh

# Include nvm
source ~agilbert/kkdad/profile/env/zsh/nvm_setup.sh


# Fix git/gpg signing error: Inappropriate ioctl for device
export GPG_TTY=$(tty)


fixdocker()
{
  echo "sudo ln -s ~/.docker/run/docker.sock /var/run/docker.sock"
  sudo ln -s ~/.docker/run/docker.sock /var/run/docker.sock
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
    git fetch -p && git pull
    git commit -a
    git push
  popd	
}

# Refresh and reload the .zshrc file
refreshZsh() {
  set -x
  if [ "$HOME/kkdad/profile/env/zsh/dot.zshrc" -nt "$HOME/.zshrc" ]; then
    cp "$HOME/kkdad/profile/env/zsh/dot.zshrc" "$HOME/.zshrc"
  elif [ "$HOME/.zshrc" -nt "$HOME/kkdad/profile/env/zsh/dot.zshrc" ]; then
    cp "$HOME/.zshrc" "$HOME/kkdad/profile/env/zsh/dot.zshrc"
  fi
  set +x
  source "$HOME/.zshrc"
}

rebase() 
{
   set -x
   CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
   git checkout master
   git fetch -p && git pull
   git pull
   git checkout $CURRENT_BRANCH
   git rebase master
   set +x
}

zeros() 
{
  set -x
  kubectl get pods | grep 0/
  set +x 
}

killzeros() 
{
  set -x
  kubectl get pods | grep 0/ | awk '{print$1}' | xargs kubectl delete pod
  set +x
}

ksetup()
{
  set -x
  sh ~/Downloads/agilbert-setup
  rm ~/Downloads/agilbert-setup
  set +x
 
}


klogs()
{
   TARGET_POD=$1
   kubectl get pods | egrep "^${TARGET_POD}-*" | head -1 | awk '{print$1}' | xargs kubectl logs -c app --tail=1 -f | jq ' .m '
}

klog()
{
   TARGET_POD=$1
   kubectl get pods | egrep "^${TARGET_POD}-*" | head -1 | awk '{print$1}' | xargs kubectl logs -c app -f
}

java11() {
  set -x
  export JAVA_HOME=$(/usr/libexec/java_home -v 11.0.15)
  set +x
}

java17() {
  set -x
  export JAVA_HOME=$(/usr/libexec/java_home -v 17.0.5)
  set +x
}

# The cleanbranches function checks the current Git repository for any modified files.
# If there are modified files, it prints a message and returns without making any changes.
# If there are no modified files, it checks out the master branch, fetches the latest changes,
# and deletes any local branches that have been deleted on the remote repository.
cleanbranches() {
      set -x
      if [[ -n $(git status --porcelain) ]]; then
         echo "There are modified files. No changes will be made."
      return
      fi
      git checkout master
      git fetch -p;
      for branch in $(git for-each-ref --format '%(refname) %(upstream:track)' | awk '$2 == "[gone]" {sub("refs/heads/", "", $1); print $1}'); do 
         git branch -D $branch; 
      done
      set +x
}

# The clean_all_branches function iterates over each directory in ~/git.
# For each directory, it navigates into it, calls the cleanbranches function,
# and then navigates back to the original directory.
clean_all_branches() {
   for dir in ~/git/*; do
      if [ -d "$dir" ]; then
         cd "$dir"
         echo "Cleaning branches in $dir"
         cleanbranches
         cd -
      fi
   done
}

cleandynamo() {
  echo "curl --location --request DELETE 'https://card-funding-srvc-agilbert.actuator.stacks.kube.usw2.ondemand.upgrade.com/api/dynamo'"
  curl --location --request DELETE 'https://card-funding-srvc-agilbert.actuator.stacks.kube.usw2.ondemand.upgrade.com/api/dynamo'
}

