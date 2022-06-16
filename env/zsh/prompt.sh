autoload -Uz vcs_info

find_git_dirty() {
  local gstatus=$(git status --porcelain 2> /dev/null)
  if [[ "$gstatus" != "" ]]; then
    git_dirty='*'
  else
    git_dirty=''
  fi
}

precmd() { 
  vcs_info
  find_git_dirty 
}


# Format the vcs_info_msg_0_ variable
zstyle ':vcs_info:git:*' formats '(%b)'
 
# Set up the prompt (with git branch name)
setopt PROMPT_SUBST
PROMPT="%n@%m %F{green}${PWD/#$HOME/~} %F{cyan}${vcs_info_msg_0_}%F{red}${git_dirty}%F{lightgrey} %# "
