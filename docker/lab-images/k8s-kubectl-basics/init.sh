#!/bin/bash
# Start k3s
k3s server --disable traefik &>/tmp/k3s.log &
echo "Starting Kubernetes cluster..."
until kubectl get nodes &>/dev/null 2>&1; do sleep 2; done
echo "Cluster ready!"
kubectl get nodes
echo ""
echo "Try: kubectl get pods --all-namespaces"
