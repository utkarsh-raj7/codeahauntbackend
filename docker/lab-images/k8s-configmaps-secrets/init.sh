#!/bin/bash
k3s server --disable traefik &>/tmp/k3s.log &
until kubectl get nodes &>/dev/null 2>&1; do sleep 2; done
echo "Tasks:"
echo "1. Create a ConfigMap with APP_ENV=production"
echo "2. Create a Secret with DB_PASSWORD=supersecret"
echo "3. Mount both into a pod and verify the values"
