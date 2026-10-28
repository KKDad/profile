# Run ssh-agent, if it's not already running. Git Bash on Windows has no pgrep.
###############################################################
if command -v pgrep > /dev/null 2>&1; then
  SSH_PID_COUNT=$(pgrep ssh-agent | wc -l | awk '{$1=$1};1')
  if [ "$SSH_PID_COUNT" = "0" ]; then
     eval "$(ssh-agent -s)"
  fi
fi
