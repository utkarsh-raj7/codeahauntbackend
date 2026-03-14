#!/bin/bash
# ═══ K8s Basics — Pod Creation & Management ═══

mkdir -p ~/exercises

cat > ~/exercises/01-pod.yaml << 'YAML'
apiVersion: v1
kind: Pod
metadata:
  name: test-pod
  labels:
    app: test
spec:
  containers:
  - name: nginx
    image: nginx:1.25
    ports:
    - containerPort: 80
YAML

cat > ~/exercises/02-multi-container.yaml << 'YAML'
apiVersion: v1
kind: Pod
metadata:
  name: multi-pod
  labels:
    app: multi
spec:
  containers:
  - name: web
    image: nginx:1.25
    ports:
    - containerPort: 80
  - name: sidecar
    image: busybox:1.36
    command: ["sh", "-c", "while true; do echo 'sidecar running'; sleep 10; done"]
YAML

cat > ~/exercises/03-resource-limits.yaml << 'YAML'
apiVersion: v1
kind: Pod
metadata:
  name: limited-pod
spec:
  containers:
  - name: app
    image: nginx:1.25
    resources:
      requests:
        memory: "64Mi"
        cpu: "100m"
      limits:
        memory: "128Mi"
        cpu: "250m"
YAML

cat > ~/GUIDE.md << 'GUIDE'
# ☸ Kubernetes Basics — Pod Creation & Management

## Objective
Learn to create, inspect, and manage Kubernetes Pods using kubectl.
Uses `--dry-run=client` mode — no live cluster needed!

## Exercises

### 1. Explore kubectl
```bash
kubectl version --client
kubectl api-resources | head -20
kubectl explain pod
kubectl explain pod.spec.containers
```

### 2. Create Pods (dry-run)
```bash
kubectl apply -f ~/exercises/01-pod.yaml --dry-run=client -o yaml
kubectl run quick-pod --image=nginx --dry-run=client -o yaml
```

### 3. Generate YAML from CLI
```bash
kubectl run my-nginx --image=nginx:1.25 --port=80 --dry-run=client -o yaml
kubectl run my-redis --image=redis:7 --dry-run=client -o yaml > ~/exercises/redis-pod.yaml
cat ~/exercises/redis-pod.yaml
```

### 4. Multi-container Pods
```bash
cat ~/exercises/02-multi-container.yaml
kubectl apply -f ~/exercises/02-multi-container.yaml --dry-run=client -o yaml
```

### 5. Resource Limits
```bash
cat ~/exercises/03-resource-limits.yaml
kubectl apply -f ~/exercises/03-resource-limits.yaml --dry-run=client -o yaml
kubectl explain pod.spec.containers.resources
```

## Key Concepts
- **Pod**: Smallest deployable unit, wraps one or more containers
- **Labels**: Key-value pairs for organizing and selecting resources
- **Resources**: CPU/memory requests and limits
- **Multi-container**: Sidecar pattern for logging, proxying, etc.
GUIDE

echo ""
echo -e "\033[1;34m╔══════════════════════════════════════════╗\033[0m"
echo -e "\033[1;34m║    ☸ Kubernetes Basics                   ║\033[0m"
echo -e "\033[1;34m╚══════════════════════════════════════════╝\033[0m"
echo ""
echo -e "\033[33m📂 Manifests:\033[0m ~/exercises/*.yaml"
echo -e "\033[33m📖 Guide:\033[0m     cat ~/GUIDE.md"
echo ""
echo -e "\033[90mUses --dry-run=client mode (no live cluster needed)\033[0m"
echo -e "\033[90mStart with: kubectl version --client\033[0m"
echo ""
