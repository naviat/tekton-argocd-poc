#!/bin/bash
set -e

command_exists () {
    type "$1" &> /dev/null ;
}

if command_exists k3d ; then
    echo "START--- Create PoC cluster ---"
    k3d registry create local-registry --port 5000
    k3d cluster create tekton-poc-cluster -p "9001:9001@loadbalancer" -p "9000:9000@loadbalancer" -p "9080:9080@loadbalancer" --registry-config "./conf/k3d/tekton-registry.yaml"
else
    echo "Install k3d to start PoC"
    curl -s https://raw.githubusercontent.com/rancher/k3d/main/install.sh | bash
    k3d registry create local-registry --port 5000
    k3d cluster create tekton-poc-cluster -p "9001:9001@loadbalancer" -p "9000:9000@loadbalancer" -p "9080:9080@loadbalancer" --registry-config "./conf/k3d/tekton-registry.yaml"
fi
