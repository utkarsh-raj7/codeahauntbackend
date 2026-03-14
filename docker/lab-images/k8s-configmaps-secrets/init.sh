#!/bin/bash
# ═══ K8s ConfigMaps & Secrets ═══

mkdir -p ~/exercises

cat > ~/exercises/01-configmap.yaml << 'YAML'
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  APP_ENV: "production"
  LOG_LEVEL: "info"
  DATABASE_HOST: "postgres.default.svc.cluster.local"
  app.properties: |
    server.port=8080
    server.name=my-app
    feature.dark-mode=true
YAML

cat > ~/exercises/02-secret.yaml << 'YAML'
apiVersion: v1
kind: Secret
metadata:
  name: db-credentials
type: Opaque
stringData:
  DB_USERNAME: admin
  DB_PASSWORD: supersecret123
  DATABASE_URL: "postgres://admin:supersecret123@postgres:5432/mydb"
YAML

cat > ~/exercises/03-pod-with-config.yaml << 'YAML'
apiVersion: v1
kind: Pod
metadata:
  name: configured-app
spec:
  containers:
  - name: app
    image: nginx:1.25
    envFrom:
    - configMapRef:
        name: app-config
    - secretRef:
        name: db-credentials
    volumeMounts:
    - name: config-volume
      mountPath: /etc/app-config
      readOnly: true
  volumes:
  - name: config-volume
    configMap:
      name: app-config
YAML

cat > ~/exercises/04-env-specific.yaml << 'YAML'
apiVersion: v1
kind: Pod
metadata:
  name: selective-env
spec:
  containers:
  - name: app
    image: nginx:1.25
    env:
    - name: DATABASE_URL
      valueFrom:
        secretKeyRef:
          name: db-credentials
          key: DATABASE_URL
    - name: APP_ENV
      valueFrom:
        configMapKeyRef:
          name: app-config
          key: APP_ENV
YAML

cat > ~/GUIDE.md << 'GUIDE'
# ☸ K8s ConfigMaps & Secrets

## Objective
Learn to manage configuration and sensitive data in Kubernetes.

## Exercises

### 1. Create a ConfigMap
```bash
cat ~/exercises/01-configmap.yaml
kubectl apply -f ~/exercises/01-configmap.yaml --dry-run=client -o yaml
kubectl create configmap my-cm --from-literal=key1=val1 --from-literal=key2=val2 --dry-run=client -o yaml
```

### 2. Create a Secret
```bash
cat ~/exercises/02-secret.yaml
kubectl apply -f ~/exercises/02-secret.yaml --dry-run=client -o yaml
kubectl create secret generic my-secret --from-literal=password=s3cur3 --dry-run=client -o yaml
```

### 3. Mount into a Pod (envFrom)
```bash
cat ~/exercises/03-pod-with-config.yaml
kubectl apply -f ~/exercises/03-pod-with-config.yaml --dry-run=client -o yaml
# Note: envFrom injects ALL keys as environment variables
# volumeMounts makes keys available as files at /etc/app-config/
```

### 4. Selective env vars (valueFrom)
```bash
cat ~/exercises/04-env-specific.yaml
kubectl apply -f ~/exercises/04-env-specific.yaml --dry-run=client -o yaml
# Note: valueFrom picks specific keys from ConfigMap/Secret
```

### 5. Explore the API
```bash
kubectl explain configmap
kubectl explain secret
kubectl explain pod.spec.containers.envFrom
kubectl explain pod.spec.containers.env.valueFrom
kubectl explain pod.spec.volumes
```

## Key Concepts
- **ConfigMap**: Non-sensitive config (env vars, config files)
- **Secret**: Sensitive data (passwords, tokens, keys)
- **envFrom**: Inject all keys from ConfigMap/Secret as env vars
- **valueFrom**: Pick a specific key from ConfigMap/Secret
- **volumeMount**: Mount ConfigMap/Secret as files in the container
GUIDE

echo ""
echo -e "\033[1;33m╔══════════════════════════════════════════╗\033[0m"
echo -e "\033[1;33m║    ☸ K8s ConfigMaps & Secrets            ║\033[0m"
echo -e "\033[1;33m╚══════════════════════════════════════════╝\033[0m"
echo ""
echo -e "\033[33m📂 Manifests:\033[0m ~/exercises/*.yaml"
echo -e "\033[33m📖 Guide:\033[0m     cat ~/GUIDE.md"
echo ""
echo -e "\033[90mStart with: cat ~/exercises/01-configmap.yaml\033[0m"
echo ""
