#!/bin/bash

set -e

source gcp.sh

function deploy_coredns_opa {
  local cluster=$1
  local image=$2
  sed -e s%__IMAGE__%$image%g coredns-opa.yaml | kubectl --kubeconfig $GCP_KUBECONFIG --context $cluster apply -f -
}

cluster=$1
image=${2:-gcr.io/jbelamaric-public/coredns:opa-v1.6.6}

if [[ -z $cluster ]]; then
  echo "Usage: $0 <context> [ <image> ]"
  exit 1
fi


deploy_coredns_opa $cluster $image
