#!/bin/bash
# ═══ K8s Services — Exposing & Networking ═══

mkdir -p ~/exercises

cat > ~/exercises/01-clusterip.yaml << 'YAML'
apiVersion: v1
kind: Service
metadata:
  name: web-svc
spec:
  type: ClusterIP
  selector:
    app: web-app
  ports:
  - port: 80
    targetPort: 80
    protocol: TCP
YAML

cat > ~/exercises/02-nodeport.yaml << 'YAML'
apiVersion: v1
kind: Service
metadata:
  name: web-nodeport
spec:
  type: NodePort
  selector:
    app: web-app
  ports:
  - port: 80
    targetPort: 80
    nodePort: 30080
YAML

cat > ~/exercises/03-deployment.yaml << 'YAML'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: web-app
  template:
    metadata:
      labels:
        app: web-app
    spec:
      containers:
      - name: nginx
        image: nginx:1.25
        ports:
        - containerPort: 80
YAML

cat > ~/exercises/04-headless.yaml << 'YAML'
apiVersion: v1
kind: Service
metadata:
  name: web-headless
spec:
  clusterIP: None
  selector:
    app: web-app
  ports:
  - port: 80
    targetPort: 80
YAML

cat > ~/GUIDE.md << 'GUIDE'
# ☸ K8s Services — Exposing & Networking

## Objective
Learn the different Service types: ClusterIP, NodePort, and Headless.

## Exercises

### 1. ClusterIP (default)
```bash
cat ~/exercises/01-clusterip.yaml
kubectl apply -f ~/exercises/01-clusterip.yaml --dry-run=client -o yaml
kubectl create service clusterip my-svc --tcp=8080:80 --dry-run=client -o yaml
```

### 2. NodePort
```bash
cat ~/exercises/02-nodeport.yaml
kubectl apply -f ~/exercises/02-nodeport.yaml --dry-run=client -o yaml
kubectl create service nodeport my-np --tcp=80:80 --node-port=30001 --dry-run=client -o yaml
```

### 3. Link Deployment + Service
```bash
cat ~/exercises/03-deployment.yaml
cat ~/exercises/01-clusterip.yaml
# Note how selector.app matches template.metadata.labels.app
```

### 4. Headless Service
```bash
cat ~/exercises/04-headless.yaml
kubectl explain service.spec.clusterIP
# clusterIP: None = DNS returns Pod IPs directly
```

### 5. Explore Service spec
```bash
kubectl explain service.spec
kubectl explain service.spec.type
kubectl explain service.spec.ports
```

## Service Types
| Type | Use Case |
|------|----------|
| **ClusterIP** | Internal-only access (default) |
| **NodePort** | External access via node IP:port |
| **LoadBalancer** | Cloud provider load balancer |
| **Headless** | DNS-only, no proxy (StatefulSets) |
GUIDE

echo ""
echo -e "\033[1;36m╔══════════════════════════════════════════╗\033[0m"
echo -e "\033[1;36m║    ☸ K8s Services                        ║\033[0m"
echo -e "\033[1;36m╚══════════════════════════════════════════╝\033[0m"
echo ""
echo -e "\033[33m📂 Manifests:\033[0m ~/exercises/*.yaml"
echo -e "\033[33m📖 Guide:\033[0m     cat ~/GUIDE.md"
echo ""
echo -e "\033[90mStart with: cat ~/exercises/01-clusterip.yaml\033[0m"
echo ""
