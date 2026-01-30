# Performance optimization: Cache completions daily
autoload -Uz compinit
if [ "$(date +'%j')" != "$(stat -f '%Sm' -t '%j' ~/.zcompdump 2>/dev/null)" ]; then
  compinit
else
  compinit -C
fi

# Profiling support (uncomment to enable)
# zmodload zsh/zprof

# History configuration
###############################################################
HISTFILE=~/.zsh_history
HISTSIZE=50000
SAVEHIST=50000
setopt EXTENDED_HISTORY          # Write the history file in the ':start:elapsed;command' format
setopt HIST_EXPIRE_DUPS_FIRST    # Expire a duplicate event first when trimming history
setopt HIST_FIND_NO_DUPS         # Do not display a previously found event
setopt HIST_IGNORE_ALL_DUPS      # Delete an old recorded event if a new event is a duplicate
setopt HIST_IGNORE_DUPS          # Do not record an event that was just recorded again
setopt HIST_IGNORE_SPACE         # Do not record an event starting with a space
setopt HIST_SAVE_NO_DUPS         # Do not write a duplicate event to the history file
setopt HIST_VERIFY               # Do not execute immediately upon history expansion
setopt INC_APPEND_HISTORY        # Write to the history file immediately, not when the shell exits
setopt SHARE_HISTORY             # Share history between all sessions

# Extended globbing and other shell options
###############################################################
setopt EXTENDED_GLOB             # Enable extended globbing
setopt AUTO_CD                   # Auto change to a directory without typing cd
setopt CORRECT                   # Try to correct the spelling of commands

# Aliases
###############################################################
alias ls='ls -G'
alias ll='ls -al -G'
alias kcdb='kubectl --context=agilbert port-forward postgres-0 5432:5432'
alias kcdbs='kubectl port-forward service/spectrum-db 1433:1433'
alias grc='git rebase --continue'
alias kclss='klog creditline-servicing-srvc'
alias kclsm='klog creditline-servicing-srvc'
alias klac='klog loan-app-creation-srvc'
alias explorer=open
alias opex='cd ~/git/pcl-ai-tools && claude'


# Update Path
###############################################################
export PATH="/opt/homebrew/opt/libpq/bin:$PATH"
export PATH="${PATH}:/Applications/Visual Studio Code.app/Contents/Resources/app/bin"
export PATH="${PATH}:/Users/agilbert/bin"
export JAVA_HOME=`/usr/libexec/java_home`

# Autosuggestion configuration
###############################################################
if command -v zsh-autosuggestions &> /dev/null || [ -f "${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh" ]; then
  ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20
  ZSH_AUTOSUGGEST_USE_ASYNC=1
  ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#666666"
fi

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


# Check if current directory is in a credit-card repository
###############################################################
is_credit_card_repo() {
  # Check if we're in a git repository
  if ! git rev-parse --is-inside-work-tree &> /dev/null; then
    return 1
  fi

  # Get the repository root
  local repo_root
  repo_root=$(git rev-parse --show-toplevel 2>/dev/null)
  if [[ -z "$repo_root" ]]; then
    return 1
  fi

  # Check if repo is under ~/git/credit-card-*
  local expected_prefix="${HOME}/git/credit-card-"
  if [[ "$repo_root" == ${expected_prefix}* ]]; then
    return 0
  fi

  return 1
}


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


# Update and sync .zshrc with git repository
update()
{
  if ! command -v vi &> /dev/null; then
    echo "Error: vi command not found"
    return 1
  fi
  
  vi ~/.zshrc || return 1
  source ~/.zshrc || return 1
  cp ~/.zshrc ~/kkdad/profile/env/zsh/dot.zshrc || return 1
  
  pushd ~/kkdad/profile > /dev/null || return 1
    git fetch -p && git pull || { popd > /dev/null; return 1; }
    git commit -a || { popd > /dev/null; return 1; }
    git push || { popd > /dev/null; return 1; }
  popd > /dev/null
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

# Rebase current branch onto master
rebase() 
{
   if ! git rev-parse --is-inside-work-tree &> /dev/null; then
     echo "Error: Not in a git repository"
     return 1
   fi
   
   set -x
   local CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
   if [[ -z "$CURRENT_BRANCH" ]]; then
     echo "Error: Could not determine current branch"
     set +x
     return 1
   fi
   
   git checkout master || { set +x; return 1; }
   git fetch -p && git pull || { set +x; return 1; }
   git checkout "$CURRENT_BRANCH" || { set +x; return 1; }
   git rebase master || { set +x; return 1; }
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

# Setup kubectl configuration
ksetup()
{
  local setup_file=~/Downloads/agilbert-setup
  if [[ ! -f "$setup_file" ]]; then
    echo "Error: Setup file not found at $setup_file"
    return 1
  fi
  
  set -x
  sh "$setup_file" || { set +x; return 1; }
  rm "$setup_file" || { set +x; return 1; }
  set +x
}


# Get formatted logs from a Kubernetes pod
klogs()
{
   local TARGET_POD=$1
   if [[ -z "$TARGET_POD" ]]; then
     echo "Error: Pod name required"
     echo "Usage: klogs <pod-name>"
     return 1
   fi
   
   if ! command -v kubectl &> /dev/null; then
     echo "Error: kubectl not found"
     return 1
   fi
   
   if ! command -v jq &> /dev/null; then
     echo "Error: jq not found"
     return 1
   fi
   
   kubectl get pods | egrep "^${TARGET_POD}-*" | head -1 | awk '{print$1}' | xargs kubectl logs -c app --tail=1 -f | jq ' .m '
}

# Get raw logs from a Kubernetes pod
klog()
{
   local TARGET_POD=$1
   if [[ -z "$TARGET_POD" ]]; then
     echo "Error: Pod name required"
     echo "Usage: klog <pod-name>"
     return 1
   fi
   
   if ! command -v kubectl &> /dev/null; then
     echo "Error: kubectl not found"
     return 1
   fi
   
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

# Clean up local branches that have been deleted on remote
# Checks for modified files first and safely deletes only "gone" branches
# Usage: cleanbranches
cleanbranches() {
      if ! git rev-parse --is-inside-work-tree &> /dev/null; then
        echo "Error: Not in a git repository"
        return 1
      fi
      
      set -x
      if [[ -n $(git status --porcelain) ]]; then
         echo "There are modified files. No changes will be made."
         set +x
         return 1
      fi
      
      git checkout master || { set +x; return 1; }
      git fetch -p || { set +x; return 1; }
      
      for branch in $(git for-each-ref --format '%(refname) %(upstream:track)' | awk '$2 == "[gone]" {sub("refs/heads/", "", $1); print $1}'); do 
         git branch -D "$branch" || echo "Failed to delete branch: $branch"
      done
      set +x
}

# Clean branches in all git repositories under ~/git/
# Iterates through each directory and runs cleanbranches function
# Usage: clean_all_branches
clean_all_branches() {
   local original_dir=$(pwd)
   
   if [[ ! -d ~/git ]]; then
     echo "Error: ~/git directory does not exist"
     return 1
   fi
   
   for dir in ~/git/*; do
      if [[ -d "$dir" ]]; then
         cd "$dir" || continue
         echo "Cleaning branches in $dir"
         cleanbranches
         cd "$original_dir" || return 1
      fi
   done
}

cleandynamo() {
  echo "curl --location --request DELETE 'https://card-funding-srvc-agilbert.actuator.stacks.kube.usw2.ondemand.upgrade.com/api/dynamo'"
  curl --location --request DELETE 'https://card-funding-srvc-agilbert.actuator.stacks.kube.usw2.ondemand.upgrade.com/api/dynamo'
}



## PodMan support
export DOCKER_HOST=unix://$(podman machine inspect --format '{{.ConnectionInfo.PodmanSocket.Path}}')
export TESTCONTAINERS_DOCKER_SOCKET_OVERRIDE=/var/run/docker.sock
alias docker=podman
export PATH="$PATH:/Users/agilbert/git/claude_memory/commands"

export COLUMNS="120"

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

  # 🏷️ Set badge to repo name (or blank)
  if [[ -n "$repo" ]]; then
    printf "\033]1337;SetBadgeFormat=%s\a" "$(echo -n "$repo" | base64)"
  else
    printf "\033]1337;SetBadgeFormat=%s\a" "$(echo -n "" | base64)"
  fi

  # 🪪 Set tab/window title (showing folder name or repo)
  local title=""
  if [[ -n "$repo" ]]; then
    title="$repo — $cwd_name"
  else
    title="$cwd_name"
  fi
  echo -ne "\033]0;${title}\007"
}

# Add to Zsh hook so it runs before each prompt
autoload -U add-zsh-hook
add-zsh-hook precmd update_iterm2_badge_and_title

# Show profiling results (uncomment if zprof is enabled above)
# zprof

