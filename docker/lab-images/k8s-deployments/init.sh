#!/bin/bash
# ═══ K8s Deployments — Scaling & Rolling Updates ═══

mkdir -p ~/exercises

cat > ~/exercises/01-deployment.yaml << 'YAML'
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
        image: nginx:1.24
        ports:
        - containerPort: 80
        resources:
          limits:
            memory: "128Mi"
            cpu: "250m"
YAML

cat > ~/exercises/02-scaled.yaml << 'YAML'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app
spec:
  replicas: 5
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

cat > ~/exercises/03-rolling-update.yaml << 'YAML'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app
spec:
  replicas: 3
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
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

cat > ~/GUIDE.md << 'GUIDE'
# ☸ K8s Deployments — Scaling & Rolling Updates

## Objective
Learn to create Deployments, scale replicas, and perform rolling updates.

## Exercises

### 1. Create a Deployment
```bash
cat ~/exercises/01-deployment.yaml
kubectl apply -f ~/exercises/01-deployment.yaml --dry-run=client -o yaml
kubectl create deployment redis-cache --image=redis:7 --replicas=2 --dry-run=client -o yaml
```

### 2. Scale Replicas
```bash
kubectl scale deployment web-app --replicas=5 --dry-run=client -o yaml 2>/dev/null || \
  echo "In dry-run: edit replicas in YAML directly"
cat ~/exercises/02-scaled.yaml
diff ~/exercises/01-deployment.yaml ~/exercises/02-scaled.yaml
```

### 3. Rolling Update Strategy
```bash
cat ~/exercises/03-rolling-update.yaml
kubectl explain deployment.spec.strategy
kubectl explain deployment.spec.strategy.rollingUpdate
```

### 4. Generate from CLI
```bash
kubectl create deployment my-app --image=node:18 --replicas=3 --dry-run=client -o yaml
kubectl create deployment multi-svc --image=redis:7 --dry-run=client -o yaml
```

### 5. Understand Selectors
```bash
kubectl explain deployment.spec.selector
kubectl explain deployment.spec.template.metadata.labels
```

## Key Concepts
- **Deployment** manages ReplicaSets for declarative updates
- **replicas** controls how many Pod copies run
- **RollingUpdate** replaces pods gradually (maxSurge/maxUnavailable)
- **Recreate** kills all old pods before creating new ones
GUIDE

echo ""
echo -e "\033[1;35m╔══════════════════════════════════════════╗\033[0m"
echo -e "\033[1;35m║    ☸ K8s Deployments                     ║\033[0m"
echo -e "\033[1;35m╚══════════════════════════════════════════╝\033[0m"
echo ""
echo -e "\033[33m📂 Manifests:\033[0m ~/exercises/*.yaml"
echo -e "\033[33m📖 Guide:\033[0m     cat ~/GUIDE.md"
echo ""
echo -e "\033[90mStart with: cat ~/exercises/01-deployment.yaml\033[0m"
echo ""
