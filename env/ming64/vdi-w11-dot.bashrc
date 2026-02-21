

update()
{
  set -x
  vi ~/.bashrc
  source ~/.bashrc
  cp ~/.bashrc /c/git/profile/env/ming64/vdi-w10-dot.bashrc
  pushd /c/git/profile
    git commit -a
    git push
  popd
  set +x	
}

updateAll() 
{
  set -x
  for dir in /c/git/*; do 
    (cd "$dir" && git fetch -p && git pull); 
  done
  set +x
}