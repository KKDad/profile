autoload -Uz compinit && compinit

alias ls='ls --color'
alias ll='ls -al --color'
alias kcdb='kubectl --context=agilbert port-forward postgres-0 5432:5432'

alias explorer=open

# Add psql and libraries to path
export PATH="/opt/homebrew/opt/libpq/bin:$PATH"
export PATH="/opt/node-v18.15.0-darwin-arm64/bin:$PATH"

# Run ssh-agent, if it's not already running
SSH_PID_COUNT=`pgrep ssh-agent | wc -l | awk '{$1=$1};1'`
if [ "$SSH_PID_COUNT" = "0" ]; then 
   eval "$(ssh-agent -s)"
fi

# Include a new prompt with Git support
source ~agilbert/git/profile/env/zsh/prompt.sh

# Include nvm
source ~agilbert/git/profile/env/zsh/nvm_setup.sh


export PATH="${PATH}:/Applications/Visual Studio Code.app/Contents/Resources/app/bin"
export JAVA_HOME=`/usr/libexec/java_home -v 21`

# Fix git/gpg signing error: Inappropriate ioctl for device
export GPG_TTY=$(tty)

# Homebrew on Apple Silicon
alias brow='arch --x86_64 /usr/local/Homebrew/bin/brew'
path=('/opt/homebrew/bin' $path)
 
# Alias for running intel commands
alias ib='PATH=/usr/local/bin'

update()
{
  set -x
  vi ~/.zshrc
  source ~/.zshrc
  cp ~/.zshrc ~/git/profile/env/zsh/laptop-dot.zshrc
  pushd ~/git/profile
    git commit -a
    git push
  popd
  set +x	
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

cleanbranches() {
   set -x
   git fetch -p;
   for branch in $(git for-each-ref --format '%(refname) %(upstream:track)' | awk '$2 == "[gone]" {sub("refs/heads/", "", $1); print $1}'); do 
      git branch -D $branch; 
   done
   set +x
}

# Added by Antigravity
export PATH="/Users/agilbert/.antigravity/antigravity/bin:$PATH"
