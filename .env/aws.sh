export CLUSTER_NAME='agilbert-c1'

alias minions='ls -1 /var/cache/salt/master/minions'
alias getweb="sudo salt ${CLUSTER_NAME}-interset cmd.run 'curl http://169.254.169.254/latest/meta-data/public-hostname'"


function teardown {
    pushd ~
        sudo rm -f *.log
        sudo salt-run --log-level info --out-file interset-salt-delete-ingest-all.log state.orch aws-terminate.delete-ingest-all
        sleep 10

        sudo salt-run --log-level info --out-file interset-salt-delete-emr-cluster.log state.orch aws-terminate.delete-emr-cluster
        sleep 10

        sudo salt-run --log-level info --out-file interset-salt-delete-elastic.log state.orch aws-terminate.delete-elastic
        sleep 10

        sudo salt-run --log-level info --out-file interset-salt-delete-interset-master.log state.orch aws-terminate.delete-interset-master
        sleep 10

        sudo salt-run --log-level info --out-file interset-salt-delete-monitoring-node.log state.orch aws-terminate.delete-monitoring-node
    popd
}

function rebuild {
    pushd ~
        sudo salt-run saltutil.sync_all
        sudo salt-run --log-level info --out-file interset-salt-1-provision.log state.orch aws-provision
        sleep 10

        sudo salt-run state.orch aws-maintenance.ssh-config
        sleep 10
        
        sudo salt "*" state.apply monitoring.install-node-exporter
        sleep 10

        sudo salt-run --log-level info state.orch aws-provision.update-phoenix-jars
        sleep 10

        sudo salt $(sudo salt \* grains.get 'the_master_ip' --output=text | cut -d ' ' -f 2) state.apply aws-provision.update-emr-jars 
        sleep 10

        sudo salt-run --log-level info --out-file interset-salt-2-orchestration.log state.orch crowdstrike.deploy.orchestration
        sleep 10

        sudo salt-run --log-level info --out-file interset-salt-3-setup-crowdstrike-ingest.log state.orch crowdstrike.ingest.setup-all
    popd
}