alias minions='echo "ls -1 /var/cache/salt/master/minions" && ls -1 /var/cache/salt/master/minions'
alias saltping="echo \"sudo salt '*' test.ping\" && sudo salt '*' test.ping"


function getweb {
    set -x    
    sudo salt $(cat /srv/pillar/cluster.sls | grep " name:" | awk '{ print $2}' | tr -d '\n' | tr -d '\r')-interset cmd.run 'curl http://169.254.169.254/latest/meta-data/public-hostname'
    set +x
}

function teardown {
    pushd ~
        set -x

        # delete SQS queues and Lambda functions
        sudo rm -f *.log
        sudo salt-run --log-level info --out-file interset-salt-delete-ingest-all.log state.orch aws-terminate.delete-ingest-all
        sleep 10

        # EMR cluster
        sudo salt-run --log-level info --out-file interset-salt-delete-emr-cluster.log state.orch aws-terminate.delete-emr-cluster
        sleep 10

        # Delete ElasticSearch Cluster
        sudo salt-run --log-level info --out-file interset-salt-delete-elastic.log state.orch aws-terminate.delete-elastic
        sleep 10

        # Delete the Analytics/Interset node
        sudo salt-run --log-level info --out-file interset-salt-delete-interset-master.log state.orch aws-terminate.delete-interset-master
        sleep 10

        # Delete the monitoring node
        sudo salt-run --log-level info --out-file interset-salt-delete-monitoring-node.log state.orch aws-terminate.delete-monitoring-node

        # delete avro bucket
        sudo salt-run state.orch crowdstrike.terminate.delete-avro-bucket
        sudo salt-run state.orch aws-maintenance.prune-ebs-volumes
        set +x
        echo "*****************************************************"
        echo "                 Destroy Complete"
        echo "*****************************************************"
    popd
}

# Rebuild the AWS CloudStrike cluster
function rebuild {
    pushd ~
        set -x

        # Provision VMs
        sudo rm -f *.log
        sudo salt-key --accept-all --yes
        sudo salt-run saltutil.sync_all
        sudo salt-run --log-level info --out-file interset-salt-1-provision.log state.orch aws-provision
        sleep 60

        # Enable SSH Access
        sudo salt-run state.orch aws-maintenance.ssh-config
        sleep 10
        
        # Setup Monitoring
        sudo salt "*" state.apply monitoring-prometheus.install-node-exporter
        sudo salt "*-search-1" state.apply monitoring-prometheus.install-elasticsearch-exporter
        sleep 10

        # To update the phoenix spark jars 
        sudo salt-run --log-level info state.orch aws-provision.update-phoenix-jars
        sleep 10
        sudo salt $(sudo salt \* grains.get 'the_master_ip' --output=text | cut -d ' ' -f 2) state.apply aws-provision.update-emr-jars 
        sleep 10

        # To install Interset analytics for an inital ingest and run the Interset reporting services
        date
        sudo salt-run --log-level info --out-file interset-salt-2-orchestration.log state.orch crowdstrike.deploy.orchestration
        sleep 10

        # To install and setup ingest Crowdstrike pipeline, including; Lambda functions, SQS queues, and trigger notifications
        date
        sudo salt-run --log-level info --out-file interset-salt-3-setup-crowdstrike-ingest.log state.orch crowdstrike.ingest.setup-all

        set +x
        echo "*****************************************************"
        echo "                 Rebuild Complete"
        echo "*****************************************************"
    popd
}

