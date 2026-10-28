# Entry point for zsh. ~/.zshrc is a stub written by install.sh that sets PROFILE_DIR and
# PROFILE_HOST, then sources this file.

: ${PROFILE_DIR:=${${(%):-%x}:A:h:h:h}}

# Performance optimization: Cache completions daily
autoload -Uz compinit
zmodload -F zsh/stat b:zstat
if [ "$(date +'%j')" != "$(zstat -F '%j' +mtime ~/.zcompdump 2>/dev/null)" ]; then
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

autoload -U add-zsh-hook

for module in env ssh-agent git java profile; do
  source "$PROFILE_DIR/shell/common/$module.sh"
done

for module in prompt iterm2 herdr secrets; do
  source "$PROFILE_DIR/shell/zsh/$module.zsh"
done
unset module

# Local secrets (not source-controlled). Before the host layer, which reads values from it.
###############################################################
[ -f ~/.zshrc.secrets ] && source ~/.zshrc.secrets

[ -f "$PROFILE_DIR/shell/hosts/$PROFILE_HOST.zsh" ] && source "$PROFILE_DIR/shell/hosts/$PROFILE_HOST.zsh"

# Show profiling results (uncomment if zprof is enabled above)
# zprof
