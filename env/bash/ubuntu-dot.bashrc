# Ubuntu dev box (personal)
# ~/.bashrc is deployed from this file — see ubuntu/setup.sh and the
# update/refreshBash functions below.

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

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
source ~/git/profile/env/bash/colors.sh
source ~/git/profile/env/bash/prompt.sh

alias ls='ls --color=auto'
alias grep='grep --color=auto'
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

# Update Path
###############################################################
export PATH="$HOME/.local/bin:$PATH"

# Fix git/gpg signing error: Inappropriate ioctl for device
export GPG_TTY=$(tty)

# Run ssh-agent, if it's not already running
###############################################################
SSH_PID_COUNT=$(pgrep ssh-agent | wc -l | awk '{$1=$1};1')
if [ "$SSH_PID_COUNT" = "0" ]; then
   eval "$(ssh-agent -s)"
fi

# Update and sync ~/.bashrc with the git repository
update()
{
  if ! command -v vi &> /dev/null; then
    echo "Error: vi command not found"
    return 1
  fi

  vi ~/.bashrc || return 1
  source ~/.bashrc || return 1
  cp ~/.bashrc ~/git/profile/env/bash/ubuntu-dot.bashrc || return 1

  pushd ~/git/profile > /dev/null || return 1
    git fetch -p && git pull || { popd > /dev/null; return 1; }
    git commit -a || { popd > /dev/null; return 1; }
    git push || { popd > /dev/null; return 1; }
  popd > /dev/null
}

# Refresh and reload ~/.bashrc, whichever side (repo or $HOME) is newer
refreshBash() {
  local repo_bashrc="$HOME/git/profile/env/bash/ubuntu-dot.bashrc"
  local home_bashrc="$HOME/.bashrc"

  if [ "$repo_bashrc" -nt "$home_bashrc" ]; then
    echo "Copying from repo to home..."
    cp "$repo_bashrc" "$home_bashrc"
  elif [ "$home_bashrc" -nt "$repo_bashrc" ]; then
    echo "Copying from home to repo..."
    cp "$home_bashrc" "$repo_bashrc"
  else
    echo "Files are in sync"
  fi
  source "$home_bashrc"
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
      git pull || { set +x; return 1; }

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

   git fetch origin -p || { set +x; return 1; }
   git rebase origin/master || { set +x; return 1; }
   set +x
}

export COLUMNS="120"
