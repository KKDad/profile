# MBP M2 (personal). Loaded last by shell/zsh/init.zsh.

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
path_prepend "/opt/homebrew/opt/libpq/bin"
path_append "/Applications/Visual Studio Code.app/Contents/Resources/app/bin"
path_prepend "$HOME/.local/bin"
export JAVA_HOME=$(/usr/libexec/java_home -v 25)

## Docker / Podman support
# Use docker contexts for switching between local podman and remote docker hosts
# (don't set DOCKER_HOST — it overrides docker context selection)
# Contexts: `docker context use podman` (local) | `docker context use portainer` (ssh://root@10.0.0.47)
# Podman default connection is podman-machine-default-root (rootful)
# Set up by setup/docker/setup.sh.
