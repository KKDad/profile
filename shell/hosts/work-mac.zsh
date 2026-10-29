# MBP M4 (work). Loaded last by shell/zsh/init.zsh.

# Aliases
###############################################################
alias ls='ls -G'
alias ll='ls -al -G'
alias explorer=open

# Screenshot destination (cmd-shift-3/4) — see bin/screenshot-target.sh
alias sc-clip='screenshot-target.sh clipboard'
alias sc-desk='screenshot-target.sh desktop'

# Update Path
###############################################################
path_prepend "/opt/homebrew/opt/libpq/bin"
path_append "/Applications/Visual Studio Code.app/Contents/Resources/app/bin"
path_append "$HOME/bin"
path_append "$HOME/.local/bin"
export JAVA_HOME=$(/usr/libexec/java_home -v 25)

# Autosuggestion configuration
###############################################################
if command -v zsh-autosuggestions &> /dev/null || [ -f "${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh" ]; then
  ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20
  ZSH_AUTOSUGGEST_USE_ASYNC=1
  ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#666666"
fi

source "$PROFILE_DIR/work/upgrade.zsh"
source "$PROFILE_DIR/work/maven.zsh"
