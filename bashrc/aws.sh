export CLUSTER_NAME='agilbert-c1'

alias minions='ls -1 /var/cache/salt/master/minions'
alias getweb="sudo salt ${CLUSTER_NAME}-interset cmd.run 'curl http://169.254.169.254/latest/meta-data/public-hostname'"


function teardown {
    pushd ~
        sudo rm -f *.log
        sudo salt-run --log-level info --out-file interset-salt-delete-elastic.log state.orch aws-terminate
        sleep 10

    popd
}

function rebuild {
    pushd ~
        sudo salt-run state.orch aws-maintenance.ssh-config
        sleep 10
    popd

}