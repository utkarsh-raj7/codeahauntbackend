#!/bin/bash
k3s server --disable traefik &>/tmp/k3s.log &
until kubectl get nodes &>/dev/null 2>&1; do sleep 2; done
echo "Cluster ready. Your manifests are in ~/manifests/"
echo "Task 1: Apply the deployment: kubectl apply -f manifests/deployment.yaml"
echo "Task 2: Scale to 3 replicas"
echo "Task 3: Perform a rolling update to nginx:1.25"
