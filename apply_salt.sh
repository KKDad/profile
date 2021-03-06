#!/bin/env bash

set -x

SALT_MASTER=$(cd /c/git/Intersalt/salt-master/terraform/ && terraform output salt-master-ip)
SALT_KEY=$(find  /c/git/Intersalt/keys/ -iname *.pem | head -1)
if [ -z "${SALT_MASTER}" ]; then
    echo "Unable to determine IP for saltmaster. Please correct and try again."
    exit
fi

if [ -z "${SALT_KEY}" ]; then
    echo "Unable to locate PEM key for saltmaster. Please correct and try again."
    exit
fi

ssh -i "${SALT_KEY}" "centos@${SALT_MASTER}" -t "rm -rf .bashrc .env"
scp -i "${SALT_KEY}" .bashrc "centos@${SALT_MASTER}:~/.bashrc"
scp -i "${SALT_KEY}" -r .env "centos@${SALT_MASTER}:~/.env"



# cd /c/git/Intersalt/intersalt/states && scp -i "${SALT_KEY}" -r monitoring-prometheus "centos@${SALT_MASTER}:/home/centos/Intersalt/intersalt/states"

# sudo salt 'agilbert-thursday-monitoring' state.apply monitoring-prometheus.install-prometheus ; ssh agilbert-thursday-monitoring
