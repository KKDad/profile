# Git helpers shared by every host.

alias grc='git rebase --continue'

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
