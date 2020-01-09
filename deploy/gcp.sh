#!/bin/bash

set -e

GCPLOG="/tmp/gcp.$RANDOM.log"

function gcp_load_defaults {
  GCP_ACCOUNT=$(gcloud config get-value core/account)
  GCP_PROJECT=$(gcloud config get-value core/project)
  GCP_REGION=$(gcloud config get-value compute/region)
  GCP_ZONE=$(gcloud config get-value compute/zone)
  GCP_KUBECONFIG=${GCP_KUBECONFIG:-kubeconfig}
}

function gcp_dry_run {
  if [[ $GCP_DRYRUN == "y" ]]; then
    return 0
  else
    return 1
  fi
}

function gcp_gcloud {
  echo gcloud $GCP_QUIET --account=$GCP_ACCOUNT --project=$GCP_PROJECT $*
  if ! gcp_dry_run; then
    gcloud $GCP_QUIET --account=$GCP_ACCOUNT --project=$GCP_PROJECT $*
  fi
}

function gcp_kubectl {
  echo kubectl --kubeconfig $GCP_KUBECONFIG $*
  if ! gcp_dry_run; then
    kubectl --kubeconfig $GCP_KUBECONFIG $*
  fi
}

function gcp_verify_defaults {
  local force=$1

  echo "The script will use the following values:"
  if gcp_dry_run; then
    echo "  Dry Run   : YES"
  else
    echo "  Dry Run   : NO"
  fi
  echo "  Account   : $GCP_ACCOUNT"
  echo "  Project   : $GCP_PROJECT"
  echo "  Region    : $GCP_REGION"
  echo "  Zone      : $GCP_ZONE"
  echo "  Kubeconfig: $GCP_KUBECONFIG"

  if [[ "$force" != "y" ]]; then
    read -p "Proceed (y/n)?" proceed
  else
    proceed=y
  fi

  if [[ "$proceed" != "y" ]]; then
    exit 1
  fi
}

function gcp_sa {
  local name=$1
  local project=${2:-$GCP_PROJECT}
  echo "$name@$project.iam.gserviceaccount.com"
}

function gke_get_credentials {
  local cluster=$1
  local zone=${2:-$GCP_ZONE}

  KUBECONFIG=$GCP_KUBECONFIG gcp_gcloud container clusters get-credentials --zone $zone $cluster
  local ctx=$(gcp_kubectl config get-contexts | tr -d '*' | tr -s ' ' | cut -d ' ' -f 2 | grep _$cluster)
  gcp_kubectl config rename-context $ctx $cluster
}

function gke_clusteradmin_account {
  local ctx=$1
  local account=${3:-$GCP_ACCOUNT}

  echo "Creating cluster role binding for $account as cluster-admin in context $ctx..."
  gcp_kubectl --context $ctx create clusterrolebinding $account-clusteradmin --clusterrole=cluster-admin --user=$account || echo
}

function gke_scaledown_kubedns {
  local ctx=$1

  echo "Scaling existing kube-dns-autoscaler to 0 in context $ctx..."
  gcp_kubectl --context $ctx -n kube-system scale --replicas 0 deployment/kube-dns-autoscaler

  echo "Scaling existing kube-dns to 0 in context $ctx..."
  gcp_kubectl --context $ctx -n kube-system scale --replicas 0 deployment/kube-dns
}

function gke_create_sa_secret {
  local ctx=$1
  local ns=$3
  local sa=$4

  echo "Creating service account secret..."
  gcp_kubectl --context $ctx -n kube-system delete secret $sa || echo
  gcp_kubectl --context $ctx -n kube-system create secret generic --from-file=sa.json=$sa.json $sa
}



function gke_create_isolated_zonal_cluster {
  local name=$1
  local man=${2:-104.132.0.0/14}
  local network=${3:-$name}
  local subnet=${4:-$network}
  local mstr_range=${5:-172.16.0.0/28}
  local node_range=${6:-172.16.1.0/24}
  local pods_range=${8:-10.0.0.0/16}
  local svcs_range=${9:-10.128.0.0/16}
  local region=${10:-$GCP_REGION}
  local zone=${11:-$GCP_ZONE}

  gcp_gcloud compute networks create $network --subnet-mode=custom || echo
  gcp_gcloud compute firewall-rules create $network-inbound --network $network --allow tcp:22 --source-ranges $man,$node_range,$pods_range || echo
  gcp_gcloud compute firewall-rules create $network-internal --network $network --allow tcp,udp,icmp --source-ranges $node_range,$pods_range || echo

  gcp_gcloud compute networks subnets create $subnet --network $network --range $node_range --secondary-range pods=$pods_range,services=$svcs_range --region=$region || echo

  gcp_gcloud container clusters create $name --zone=$zone --network $network --subnetwork $subnet \
    --enable-ip-alias --enable-private-nodes --master-ipv4-cidr=$mstr_range \
    --enable-master-authorized-networks --master-authorized-networks=$man,$node_range,$pods_range \
    --cluster-secondary-range-name=pods --services-secondary-range-name=services
}

function gke_delete_isolated_zonal_cluster {
  local name=$1
  local network=${2:-$name}
  local subnet=${3:-$network}
  local region=${4:-$GCP_REGION}
  local zone=${5:-$GCP_ZONE}

  gcp_kubectl config delete-context $name || echo
  gcp_gcloud container clusters delete $name || echo
  gcp_gcloud compute firewall-rules delete $network-inbound $network-internal || echo
  gcp_gcloud compute networks subnets delete $subnet || echo
  gcp_gcloud compute networks subnets delete $network-subnet || echo
  gcp_gcloud compute networks delete $network || echo
}

gcp_load_defaults
