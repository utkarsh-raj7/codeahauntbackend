#!/bin/bash
k3s server --disable traefik &>/tmp/k3s.log &
until kubectl get nodes &>/dev/null 2>&1; do sleep 2; done
kubectl create deployment web --image=nginx:alpine --replicas=2 &>/dev/null
echo "Cluster ready with a 'web' deployment running."
echo "Tasks:"
echo "1. Expose it with a ClusterIP service"
echo "2. Expose it with a NodePort service"
echo "3. Verify with: kubectl get svc"
