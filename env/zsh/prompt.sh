setopt prompt_subst
#setopt verbose 


find_git_dirty() {
  local gstatus=$(git status --porcelain 2> /dev/null)
  if [[ "$gstatus" != "" ]]; then
    git_dirty="%F{red}*"
  else
    git_dirty=""
  fi
}

find_git_branch() {
  local gbranch=$(git symbolic-ref --short HEAD 2> /dev/null)
  if [[ "$gbranch" != "" ]]; then
    git_branch=" %F{cyan}(${gbranch})"
  else
    git_branch=""
  fi
}

precmd() {
  find_git_dirty
  find_git_branch
}

PROMPT='
%F{green}%n@%m %F{yellow}%~${git_branch}%F${git_dirty}%F{reset_color}
%# '
