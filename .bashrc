# Source global definitions
if [ -f /etc/bashrc ]; then
        . /etc/bashrc
fi

alias reload="source ~/.bashrc"

source ~/.env/colors.sh
source ~/.env/prompt.sh
source ~/.env/aws.sh