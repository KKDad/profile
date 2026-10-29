# Upgrade-only shell setup. Loaded by shell/hosts/work-mac.zsh.

# Aliases
###############################################################
alias kcdb='kubectl --context=agilbert port-forward postgres-0 5432:5432'
alias kcdbs='kubectl port-forward service/spectrum-db 1433:1433'
alias kclss='klog creditline-servicing-srvc'
alias klac='klog loan-app-creation-srvc'
alias prs='python ~/runbook/my-pr-gates.py'

# Claude aliases for starting claude in specific directories
alias opex='cd ~/git/pcl-ai-tools && clear && claude'
alias cc='cd ~/git && clear && claude --permission-mode auto --model opus'
alias qa='cd ~/git/qa-automation && clear && claude --permission-mode auto'
alias jira='cd ~/claude-team3 && clear && claude --permission-mode auto'

# Alias for Telepresence & cleanup
###############################################################
alias tele='docker run -it -v $HOME:/home -p 5005:5005 --privileged docker-upgrade.artifactory.build.upgrade.com/telepresence:latest'
alias clean='yes | docker system prune'

fixdocker()
{
  echo "sudo ln -s ~/.docker/run/docker.sock /var/run/docker.sock"
  sudo ln -s ~/.docker/run/docker.sock /var/run/docker.sock
}

# Run spectrum eod
eod()
{
  echo "kubectl exec -it deployment/spectrum -- /bin/sh /docker-entrypoint.sh eod 1234 ACTIVE"
  kubectl exec -it deployment/spectrum -- /bin/sh /docker-entrypoint.sh eod 1234 ACTIVE
}

# Kubernetes
###############################################################
zeros()
{
  set -x
  kubectl get pods | grep 0/
  set +x
}

killzeros()
{
  set -x
  kubectl get pods | grep 0/ | awk '{print$1}' | xargs kubectl delete pod
  set +x
}

# Setup kubectl configuration
ksetup()
{
  local setup_file=~/Downloads/agilbert-setup
  if [[ ! -f "$setup_file" ]]; then
    echo "Error: Setup file not found at $setup_file"
    return 1
  fi

  set -x
  sh "$setup_file" || { set +x; return 1; }
  rm "$setup_file" || { set +x; return 1; }
  set +x
}

# Get formatted logs from a Kubernetes pod
klogs()
{
   local TARGET_POD=$1
   if [[ -z "$TARGET_POD" ]]; then
     echo "Error: Pod name required"
     echo "Usage: klogs <pod-name>"
     return 1
   fi

   if ! command -v kubectl &> /dev/null; then
     echo "Error: kubectl not found"
     return 1
   fi

   if ! command -v jq &> /dev/null; then
     echo "Error: jq not found"
     return 1
   fi

   kubectl get pods | egrep "^${TARGET_POD}-*" | head -1 | awk '{print$1}' | xargs kubectl logs -c app --tail=1 -f | jq ' .m '
}

# Get raw logs from a Kubernetes pod
klog()
{
   local TARGET_POD=$1
   if [[ -z "$TARGET_POD" ]]; then
     echo "Error: Pod name required"
     echo "Usage: klog <pod-name>"
     return 1
   fi

   if ! command -v kubectl &> /dev/null; then
     echo "Error: kubectl not found"
     return 1
   fi

   kubectl get pods | egrep "^${TARGET_POD}-*" | head -1 | awk '{print$1}' | xargs kubectl logs -c app -f
}

cleandynamo() {
  echo "curl --location --request DELETE 'https://card-funding-srvc-agilbert.actuator.stacks.kube.usw2.ondemand.upgrade.com/api/dynamo'"
  curl --location --request DELETE 'https://card-funding-srvc-agilbert.actuator.stacks.kube.usw2.ondemand.upgrade.com/api/dynamo'
}

## PodMan support
###############################################################
if command -v podman &> /dev/null && podman machine inspect &> /dev/null 2>&1; then
  export DOCKER_HOST=unix://$(podman machine inspect --format '{{.ConnectionInfo.PodmanSocket.Path}}')
fi
export TESTCONTAINERS_DOCKER_SOCKET_OVERRIDE=/var/run/docker.sock
alias docker=podman

# docker-credential-ecr-login uses the default AWS credential chain -- it does not
# read the --profile flag. Without this, Testcontainers image pulls fail with
# "credentials not found in native keychain" even while an SSO session is live.
# Anything needing another AWS account must now pass --profile explicitly.
export AWS_PROFILE=ci
export TESTCONTAINERS_HUB_IMAGE_NAME_PREFIX="${UPG_ECR_REGISTRY}/dockerhub/"
path_append "$HOME/git/claude_memory/commands"

ecr_login() {
    ecr_login_command="aws ecr --profile=ci get-login-password --region us-west-2 | podman login --username AWS --password-stdin 118455887602.dkr.ecr.us-west-2.amazonaws.com"
    eval "$ecr_login_command"
    if [[ $? -ne 0 ]] ; then
        echo "Failed to login to ECR. Token expired? Fetching new token..."
        aws --profile=ci sso login
        eval "$ecr_login_command"
    fi
}

# qa-agent plugin skills (analyze-service-pr, running-tests-jenkins) default to
# ~/code/qa-automation; point them at the real checkout.
export QA_AUTOMATION_DIR="$HOME/git/qa-automation"
