# Performance optimization: Cache completions daily
autoload -Uz compinit
if [ "$(date +'%j')" != "$(stat -f '%Sm' -t '%j' ~/.zcompdump 2>/dev/null)" ]; then
  compinit
else
  compinit -C
fi

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
alias ls='ls --color'
alias ll='ls -al --color'
alias kcdb='kubectl --context=agilbert port-forward postgres-0 5432:5432'
alias explorer=open

# Homebrew on Apple Silicon
alias brow='arch --x86_64 /usr/local/Homebrew/bin/brew'
path=('/opt/homebrew/bin' $path)

# Alias for running intel commands
alias ib='PATH=/usr/local/bin'

# Update Path
###############################################################
export PATH="/opt/homebrew/opt/libpq/bin:$PATH"
export PATH="${PATH}:/Applications/Visual Studio Code.app/Contents/Resources/app/bin"
export PATH="$HOME/.local/bin:$PATH"
export JAVA_HOME=$(/usr/libexec/java_home -v 25)

# Fix git/gpg signing error: Inappropriate ioctl for device
export GPG_TTY=$(tty)

export COLUMNS="120"

# Run ssh-agent, if it's not already running
###############################################################
SSH_PID_COUNT=$(pgrep ssh-agent | wc -l | awk '{$1=$1};1')
if [ "$SSH_PID_COUNT" = "0" ]; then
   eval "$(ssh-agent -s)"
fi

# Include a new prompt with Git support
source ~agilbert/git/profile/env/zsh/prompt.sh

# Include nvm
source ~agilbert/git/profile/env/zsh/nvm_setup.sh


# Update and sync .zshrc with git repository
update()
{
  if ! command -v vi &> /dev/null; then
    echo "Error: vi command not found"
    return 1
  fi

  vi ~/.zshrc || return 1
  source ~/.zshrc || return 1
  cp ~/.zshrc ~/git/profile/env/zsh/laptop-dot.zshrc || return 1

  pushd ~/git/profile > /dev/null || return 1
    git fetch -p && git pull || { popd > /dev/null; return 1; }
    git commit -a || { popd > /dev/null; return 1; }
    git push || { popd > /dev/null; return 1; }
  popd > /dev/null
}

# Refresh and reload the .zshrc file
refreshZsh() {
  local repo_zshrc="$HOME/git/profile/env/zsh/laptop-dot.zshrc"
  local home_zshrc="$HOME/.zshrc"

  if [ "$repo_zshrc" -nt "$home_zshrc" ]; then
    echo "Copying from repo to home..."
    cp "$repo_zshrc" "$home_zshrc"
  elif [ "$home_zshrc" -nt "$repo_zshrc" ]; then
    echo "Copying from home to repo..."
    cp "$home_zshrc" "$repo_zshrc"
  else
    echo "Files are in sync"
  fi
  source "$home_zshrc"
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

java25() {
  export JAVA_HOME=$(/usr/libexec/java_home -v 25)
  echo "JAVA_HOME set to $JAVA_HOME"
}

java21() {
  export JAVA_HOME=$(/usr/libexec/java_home -v 21)
  echo "JAVA_HOME set to $JAVA_HOME"
}

java17() {
  export JAVA_HOME=$(/usr/libexec/java_home -v 17)
  echo "JAVA_HOME set to $JAVA_HOME"
}

## Podman support
if command -v podman &> /dev/null && podman machine inspect &> /dev/null 2>&1; then
  export DOCKER_HOST=unix://$(podman machine inspect --format '{{.ConnectionInfo.PodmanSocket.Path}}')
fi
alias docker=podman

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

  # Set badge to repo name (or blank)
  if [[ -n "$repo" ]]; then
    printf "\033]1337;SetBadgeFormat=%s\a" "$(echo -n "$repo" | base64)"
  else
    printf "\033]1337;SetBadgeFormat=%s\a" "$(echo -n "" | base64)"
  fi

  # Set tab/window title (showing folder name or repo)
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
