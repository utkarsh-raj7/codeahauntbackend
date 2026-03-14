#!/bin/bash
# ═══════════════════════════════════════════════
# K8s kubectl Basics — Lab Init
# ═══════════════════════════════════════════════

# Create exercise manifests
mkdir -p ~/exercises

cat > ~/exercises/01-pod.yaml << 'YAML'
apiVersion: v1
kind: Pod
metadata:
  name: my-nginx
  labels:
    app: nginx
    env: lab
spec:
  containers:
  - name: nginx
    image: nginx:1.25
    ports:
    - containerPort: 80
    resources:
      limits:
        memory: "128Mi"
        cpu: "250m"
YAML

cat > ~/exercises/02-deployment.yaml << 'YAML'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app
  labels:
    app: web-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: web-app
  template:
    metadata:
      labels:
        app: web-app
    spec:
      containers:
      - name: web
        image: nginx:1.25
        ports:
        - containerPort: 80
        env:
        - name: APP_ENV
          value: "production"
        resources:
          requests:
            memory: "64Mi"
            cpu: "100m"
          limits:
            memory: "128Mi"
            cpu: "250m"
YAML

cat > ~/exercises/03-service.yaml << 'YAML'
apiVersion: v1
kind: Service
metadata:
  name: web-app-svc
spec:
  type: ClusterIP
  selector:
    app: web-app
  ports:
  - port: 80
    targetPort: 80
    protocol: TCP
YAML

cat > ~/exercises/04-configmap.yaml << 'YAML'
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  DATABASE_HOST: "postgres.default.svc.cluster.local"
  LOG_LEVEL: "info"
  app.properties: |
    server.port=8080
    server.name=my-app
    feature.flag.dark-mode=true
YAML

cat > ~/exercises/05-namespace.yaml << 'YAML'
apiVersion: v1
kind: Namespace
metadata:
  name: staging
  labels:
    env: staging
    team: platform
YAML

# Create GUIDE.md
cat > ~/GUIDE.md << 'GUIDE'
# ☸ Kubernetes kubectl Basics — Exercise Guide

## Objective
Learn kubectl commands and Kubernetes resource YAML structure.
This lab uses `--dry-run=client` mode so you can practice without a live cluster.

## Exercises

### 1. Explore kubectl
```bash
kubectl version --client           # Check kubectl version
kubectl api-resources | head -20   # See available resource types
kubectl explain pod                # Learn about Pod spec
kubectl explain pod.spec.containers   # Dig deeper
```

### 2. Validate YAML Manifests (dry-run)
```bash
kubectl apply -f ~/exercises/01-pod.yaml --dry-run=client -o yaml
kubectl apply -f ~/exercises/02-deployment.yaml --dry-run=client -o yaml
kubectl diff -f ~/exercises/03-service.yaml --dry-run=client 2>/dev/null || echo "(no cluster)"
```

### 3. Understand Resource Structure
```bash
cat ~/exercises/01-pod.yaml          # Read a Pod manifest
cat ~/exercises/02-deployment.yaml   # Read a Deployment
cat ~/exercises/03-service.yaml      # Read a Service
cat ~/exercises/04-configmap.yaml    # Read a ConfigMap
```

### 4. Generate YAML from kubectl
```bash
kubectl run test-pod --image=nginx --dry-run=client -o yaml
kubectl create deployment test-dep --image=redis --replicas=2 --dry-run=client -o yaml
kubectl create service clusterip test-svc --tcp=80:80 --dry-run=client -o yaml
kubectl create configmap test-cm --from-literal=key1=val1 --dry-run=client -o yaml
```

### 5. Work with Namespaces & Labels
```bash
kubectl create namespace dev --dry-run=client -o yaml
kubectl apply -f ~/exercises/05-namespace.yaml --dry-run=client
kubectl run labeled-pod --image=busybox --labels="app=test,env=dev" --dry-run=client -o yaml
```

## Key Concepts
- **Pod**: Smallest deployable unit, wraps one or more containers
- **Deployment**: Manages ReplicaSets, handles rolling updates
- **Service**: Stable network endpoint for a set of Pods
- **ConfigMap**: Non-sensitive config data as key-value pairs
- **Namespace**: Virtual cluster for isolation

## Tip
Use `kubectl explain <resource>.<field>` to explore any field!
GUIDE

# Welcome banner
echo ""
echo -e "\033[1;34m╔══════════════════════════════════════════╗\033[0m"
echo -e "\033[1;34m║    ☸ Kubernetes kubectl Basics           ║\033[0m"
echo -e "\033[1;34m╚══════════════════════════════════════════╝\033[0m"
echo ""
echo -e "\033[33m📂 Manifests:\033[0m ~/exercises/*.yaml"
echo -e "\033[33m📖 Guide:\033[0m     cat ~/GUIDE.md"
echo ""
echo -e "\033[90mThis lab uses --dry-run=client mode (no live cluster needed)\033[0m"
echo -e "\033[90mStart with: kubectl version --client\033[0m"
echo ""
