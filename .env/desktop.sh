# functions and aliases for development desktop


function gosalt
{
  pushd /c/git/Intersalt/salt-master/terraform
  ssh -i $(ls -1 ../../keys/*.pem) centos@$(terraform output salt-master-ip)
  popd
}

