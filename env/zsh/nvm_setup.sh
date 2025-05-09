### Node Version Manager (NVM). 
#  It allows you to install and switch between multiple versions of Node.js and npm
# Description: Setup nvm
# Dependencies: brew



# Istall nvm using brew if it's not already installed
if [ ! -d "$HOME/.nvm" ]; then
  brew install nvm
  mkdir ~/.nvm
fi
export NVM_DIR="$HOME/.nvm"
[ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"  
# This loads nvm bash_completion
[ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" 

nvm use 20
