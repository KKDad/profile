# Exports for the namespace
NS=$(kubectl get namespaces| grep arcsight-installer | awk '{ print $1}')
NAMESPACE=$NS

# Notes
#kubectl scale interset-analytics --replicas=0 -n $NS
#kubectl get pods -n $NS | grep spark | awk '{ print $1}' | xargs kubectl delete pod --force --grace-period=0
