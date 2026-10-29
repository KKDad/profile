# VDI (Windows 11, MinGW64 / Git Bash). Loaded last by shell/bash/init.bash.

# Fetch and fast-forward every repo under /c/git
updateAll()
{
  for dir in /c/git/*; do
    (cd "$dir" && git fetch -p && git pull)
  done
}
