#!/bin/bash

set -e

source gcp.sh

GCP_QUIET=""
force=n
create=n
delete=n

while [[ $# -gt 0 ]]
do
  case $1 in
    --force|-f)
      force="y"
      GCP_QUIET="-q"
      ;;
    --dry-run)
      GCP_DRYRUN=y
      ;;
    -c)
      create=y
      ;;
    -d)
      delete=y
      ;;
    *)
      cluster=$1
  esac
  shift
done

if [[ $create == "n" && $delete == "n" ]]; then
  create=y
  delete=y
fi

if [[ -z $cluster ]]; then
  echo
  echo Usage: $0 [ --force ] [ --dry-run ] [ -c ] [ -d ] clustername
  echo
  echo "  -c means create the cluster"
  echo "  -d means delete the cluster"
  echo " --force means it won't prompt you before doing anything"
  echo " --dry-run means it won't actually execute mutating gcloud and kubectl commands"
  echo
  echo If neither -c nor -d is specified, the cluster will be deleted then created.
  exit 1
fi

gcp_verify_defaults $force

if [[ $delete == "y" ]]; then
  gke_delete_isolated_zonal_cluster $cluster
fi

if [[ $create == "y" ]]; then
  gke_create_isolated_zonal_cluster $cluster

  gke_get_credentials $cluster
  gke_clusteradmin_account $cluster
  gke_scaledown_kubedns $cluster
fi


#kubectl --kubeconfig kubeconfig --context $ctx apply -f helloweb-deployment.yaml
#sed -e s/CLUSTERNAME/$ctx/ helloweb-service-clusterip.yaml | kubectl --kubeconfig kubeconfig --context $ctx apply -f -
#sed -e s/CLUSTERNAME/$ctx/ helloweb-service-headless.yaml | kubectl --kubeconfig kubeconfig --context $ctx apply -f -
