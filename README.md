# CoreDNS / OpenPolicyAgent

## Intro

Contains code to build an image of CoreDNS that includes the OPA integration,
and also to create a GKE cluster and update it to use that CoreDNS instance.

## Quick Start

### Prerequisites
* Have a [GCP](https://cloud.google.com) account and get
   [gcloud](https://cloud.google.com/sdk/gcloud/) all set up
* Install [kustomize](https://github.com/kubernetes-sigs/kustomize/blob/master/docs/INSTALL.md)

### Getting it running
1. `git clone https://github.com/coredns/coredns-opa`
1. `cd coredns-opa/deploy`
1. `./cluster.sh -c opa`
1. `kustomize build base | kubectl --kubeconfig kubeconfig --context opa apply -f -`
