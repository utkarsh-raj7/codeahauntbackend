#!/bin/bash
# Run this script from your repo root to create all lab image directories and files
# Usage: bash create_lab_images.sh

set -e
BASE="docker/lab-images"

# ══════════════════════════════════════════════════════════════════════════════
# CATEGORY 1 — LINUX FUNDAMENTALS
# ══════════════════════════════════════════════════════════════════════════════

# ── 1.1 linux-shell-basics ───────────────────────────────────────────────────
mkdir -p $BASE/linux-shell-basics
cat > $BASE/linux-shell-basics/Dockerfile << 'DOCKERFILE'
FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y \
    bash curl wget tree file findutils grep gawk coreutils nano less \
    && rm -rf /var/lib/apt/lists/*
RUN curl -fsSL https://github.com/tsl0922/ttyd/releases/download/1.7.4/ttyd.x86_64 \
    -o /usr/local/bin/ttyd && chmod +x /usr/local/bin/ttyd
RUN useradd -m -u 1000 -s /bin/bash labuser
COPY init.sh /usr/local/bin/lab-init.sh
RUN chmod +x /usr/local/bin/lab-init.sh
USER labuser
WORKDIR /home/labuser
EXPOSE 7681
ENTRYPOINT ["ttyd","-p","7681","-W","bash","--","-c","bash /usr/local/bin/lab-init.sh; exec bash"]
DOCKERFILE

cat > $BASE/linux-shell-basics/init.sh << 'INIT'
#!/bin/bash
mkdir -p ~/workspace/project/{src,docs,tests}
echo "Hello from Code-A-Haunt!" > ~/workspace/project/src/main.txt
echo "# Project Docs" > ~/workspace/project/docs/readme.md
echo "test1\ntest2\ntest3" > ~/workspace/project/tests/results.txt
for i in {1..5}; do echo "log line $i: INFO app started" >> ~/workspace/app.log; done
echo "done"
INIT

# ── 1.2 linux-permissions ────────────────────────────────────────────────────
mkdir -p $BASE/linux-permissions
cat > $BASE/linux-permissions/Dockerfile << 'DOCKERFILE'
FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y bash coreutils sudo nano \
    && rm -rf /var/lib/apt/lists/*
RUN curl -fsSL https://github.com/tsl0922/ttyd/releases/download/1.7.4/ttyd.x86_64 \
    -o /usr/local/bin/ttyd && chmod +x /usr/local/bin/ttyd
RUN useradd -m -u 1000 -s /bin/bash labuser \
    && echo "labuser ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
RUN useradd -m -u 1001 -s /bin/bash otheruser
RUN mkdir -p /var/labdata && echo "secret" > /var/labdata/secret.txt \
    && chmod 600 /var/labdata/secret.txt && chown root:root /var/labdata/secret.txt
COPY init.sh /usr/local/bin/lab-init.sh
RUN chmod +x /usr/local/bin/lab-init.sh
USER labuser
WORKDIR /home/labuser
EXPOSE 7681
ENTRYPOINT ["ttyd","-p","7681","-W","bash","--","-c","bash /usr/local/bin/lab-init.sh; exec bash"]
DOCKERFILE

cat > $BASE/linux-permissions/init.sh << 'INIT'
#!/bin/bash
mkdir -p ~/permissions-lab
echo "public content" > ~/permissions-lab/public.txt
echo "private content" > ~/permissions-lab/private.txt
chmod 644 ~/permissions-lab/public.txt
chmod 600 ~/permissions-lab/private.txt
mkdir -p ~/permissions-lab/shared
chmod 777 ~/permissions-lab/shared
echo "done"
INIT

# ── 1.3 linux-processes ──────────────────────────────────────────────────────
mkdir -p $BASE/linux-processes
cat > $BASE/linux-processes/Dockerfile << 'DOCKERFILE'
FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y \
    bash procps htop sysstat lsof cron nano \
    && rm -rf /var/lib/apt/lists/*
RUN curl -fsSL https://github.com/tsl0922/ttyd/releases/download/1.7.4/ttyd.x86_64 \
    -o /usr/local/bin/ttyd && chmod +x /usr/local/bin/ttyd
RUN useradd -m -u 1000 -s /bin/bash labuser
COPY init.sh /usr/local/bin/lab-init.sh
RUN chmod +x /usr/local/bin/lab-init.sh
USER labuser
WORKDIR /home/labuser
EXPOSE 7681
ENTRYPOINT ["ttyd","-p","7681","-W","bash","--","-c","bash /usr/local/bin/lab-init.sh; exec bash"]
DOCKERFILE

cat > $BASE/linux-processes/init.sh << 'INIT'
#!/bin/bash
# Start a background process students can find and kill
sleep 99999 &
echo $! > ~/background.pid
echo "A background process is running. Find it with: ps aux"
INIT

# ── 1.4 linux-text-processing ────────────────────────────────────────────────
mkdir -p $BASE/linux-text-processing
cat > $BASE/linux-text-processing/Dockerfile << 'DOCKERFILE'
FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y \
    bash gawk sed grep coreutils nano less \
    && rm -rf /var/lib/apt/lists/*
RUN curl -fsSL https://github.com/tsl0922/ttyd/releases/download/1.7.4/ttyd.x86_64 \
    -o /usr/local/bin/ttyd && chmod +x /usr/local/bin/ttyd
RUN useradd -m -u 1000 -s /bin/bash labuser
COPY init.sh /usr/local/bin/lab-init.sh
RUN chmod +x /usr/local/bin/lab-init.sh
USER labuser
WORKDIR /home/labuser
EXPOSE 7681
ENTRYPOINT ["ttyd","-p","7681","-W","bash","--","-c","bash /usr/local/bin/lab-init.sh; exec bash"]
DOCKERFILE

cat > $BASE/linux-text-processing/init.sh << 'INIT'
#!/bin/bash
mkdir -p ~/data
# Sample CSV for awk/cut exercises
cat > ~/data/users.csv << 'CSV'
id,name,role,score
1,alice,admin,95
2,bob,student,72
3,carol,student,88
4,dave,instructor,91
5,eve,student,63
CSV
# Sample log for grep/sed exercises
cat > ~/data/server.log << 'LOG'
2026-03-01 10:00:01 INFO  Server started on port 3000
2026-03-01 10:00:05 INFO  Database connected
2026-03-01 10:01:22 ERROR Failed to process request: timeout
2026-03-01 10:02:11 WARN  Memory usage at 80%
2026-03-01 10:03:44 ERROR Disk write failed on /dev/sdb
2026-03-01 10:04:01 INFO  Backup completed successfully
LOG
echo "Files ready in ~/data/"
INIT

# ══════════════════════════════════════════════════════════════════════════════
# CATEGORY 2 — NETWORKING BASICS
# ══════════════════════════════════════════════════════════════════════════════

# ── 2.1 networking-tools ─────────────────────────────────────────────────────
mkdir -p $BASE/networking-tools
cat > $BASE/networking-tools/Dockerfile << 'DOCKERFILE'
FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y \
    bash curl wget dnsutils iputils-ping traceroute netcat-openbsd \
    net-tools iproute2 nmap tcpdump \
    && rm -rf /var/lib/apt/lists/*
RUN curl -fsSL https://github.com/tsl0922/ttyd/releases/download/1.7.4/ttyd.x86_64 \
    -o /usr/local/bin/ttyd && chmod +x /usr/local/bin/ttyd
RUN useradd -m -u 1000 -s /bin/bash labuser
USER labuser
WORKDIR /home/labuser
EXPOSE 7681
ENTRYPOINT ["ttyd","-p","7681","-W","bash"]
DOCKERFILE

# ── 2.2 networking-http ──────────────────────────────────────────────────────
mkdir -p $BASE/networking-http
cat > $BASE/networking-http/Dockerfile << 'DOCKERFILE'
FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y \
    bash curl wget jq python3 python3-pip \
    && pip3 install httpie requests \
    && rm -rf /var/lib/apt/lists/*
RUN curl -fsSL https://github.com/tsl0922/ttyd/releases/download/1.7.4/ttyd.x86_64 \
    -o /usr/local/bin/ttyd && chmod +x /usr/local/bin/ttyd
RUN useradd -m -u 1000 -s /bin/bash labuser
COPY init.sh /usr/local/bin/lab-init.sh
RUN chmod +x /usr/local/bin/lab-init.sh
USER labuser
WORKDIR /home/labuser
EXPOSE 7681
ENTRYPOINT ["ttyd","-p","7681","-W","bash","--","-c","bash /usr/local/bin/lab-init.sh; exec bash"]
DOCKERFILE

cat > $BASE/networking-http/init.sh << 'INIT'
#!/bin/bash
# Start a tiny HTTP server students can curl against
python3 -m http.server 8080 --directory /home/labuser &>/dev/null &
echo "Local HTTP server running on port 8080"
echo "Try: curl http://localhost:8080"
INIT

# ── 2.3 networking-ssh ───────────────────────────────────────────────────────
mkdir -p $BASE/networking-ssh
cat > $BASE/networking-ssh/Dockerfile << 'DOCKERFILE'
FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y \
    bash openssh-client openssh-server sudo nano \
    && rm -rf /var/lib/apt/lists/*
RUN curl -fsSL https://github.com/tsl0922/ttyd/releases/download/1.7.4/ttyd.x86_64 \
    -o /usr/local/bin/ttyd && chmod +x /usr/local/bin/ttyd
RUN useradd -m -u 1000 -s /bin/bash labuser \
    && echo "labuser:labpass" | chpasswd
RUN mkdir /var/run/sshd
COPY init.sh /usr/local/bin/lab-init.sh
RUN chmod +x /usr/local/bin/lab-init.sh
EXPOSE 7681
ENTRYPOINT ["ttyd","-p","7681","-W","bash","--","-c","/usr/sbin/sshd; su - labuser -c 'bash /usr/local/bin/lab-init.sh; exec bash'"]
DOCKERFILE

cat > $BASE/networking-ssh/init.sh << 'INIT'
#!/bin/bash
mkdir -p ~/.ssh && chmod 700 ~/.ssh
ssh-keygen -t rsa -b 2048 -f ~/.ssh/lab_key -N "" -q
echo "SSH key generated at ~/.ssh/lab_key"
echo "Practice: ssh-copy-id, authorized_keys, config file"
INIT

# ══════════════════════════════════════════════════════════════════════════════
# CATEGORY 3 — DOCKER FUNDAMENTALS
# ══════════════════════════════════════════════════════════════════════════════
# NOTE: Docker-in-Docker labs require the container to run with
# --privileged or a DinD sidecar. Add to container.service.ts:
# HostConfig.Privileged = true  (for docker labs only, controlled via lab.requiresPrivileged flag)

# ── 3.1 docker-basics ────────────────────────────────────────────────────────
mkdir -p $BASE/docker-basics
cat > $BASE/docker-basics/Dockerfile << 'DOCKERFILE'
FROM docker:24-dind
RUN apk add --no-cache bash curl nano ttyd
RUN adduser -D -u 1000 -s /bin/bash labuser \
    && addgroup labuser docker
COPY init.sh /usr/local/bin/lab-init.sh
RUN chmod +x /usr/local/bin/lab-init.sh
EXPOSE 7681 2375
ENTRYPOINT ["ttyd","-p","7681","-W","sh","--","-c","dockerd &>/tmp/dockerd.log & sleep 3; bash /usr/local/bin/lab-init.sh; exec bash"]
DOCKERFILE

cat > $BASE/docker-basics/init.sh << 'INIT'
#!/bin/bash
echo "Waiting for Docker daemon..."
until docker info &>/dev/null; do sleep 1; done
echo "Docker is ready!"
echo "Try: docker run hello-world"
docker pull alpine:latest &>/dev/null &
INIT

# ── 3.2 docker-build ─────────────────────────────────────────────────────────
mkdir -p $BASE/docker-build
cat > $BASE/docker-build/Dockerfile << 'DOCKERFILE'
FROM docker:24-dind
RUN apk add --no-cache bash curl nano python3
RUN curl -fsSL https://github.com/tsl0922/ttyd/releases/download/1.7.4/ttyd.x86_64 \
    -o /usr/local/bin/ttyd && chmod +x /usr/local/bin/ttyd 2>/dev/null || \
    apk add --no-cache ttyd
COPY init.sh /usr/local/bin/lab-init.sh
COPY sample-app/ /home/labuser/sample-app/
RUN chmod +x /usr/local/bin/lab-init.sh
EXPOSE 7681
ENTRYPOINT ["ttyd","-p","7681","-W","bash","--","-c","dockerd &>/tmp/dockerd.log & sleep 3; bash /usr/local/bin/lab-init.sh; exec bash"]
DOCKERFILE

cat > $BASE/docker-build/init.sh << 'INIT'
#!/bin/bash
until docker info &>/dev/null; do sleep 1; done
echo "Your task: write a Dockerfile for the sample Python app in ~/sample-app/"
echo "Then build it with: docker build -t my-app ."
INIT

mkdir -p $BASE/docker-build/sample-app
cat > $BASE/docker-build/sample-app/app.py << 'PY'
from http.server import HTTPServer, BaseHTTPRequestHandler
class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.end_headers()
        self.wfile.write(b"Hello from my containerized app!")
HTTPServer(("0.0.0.0", 8080), Handler).serve_forever()
PY
cat > $BASE/docker-build/sample-app/requirements.txt << 'REQ'
# no external deps — stdlib only
REQ

# ── 3.3 docker-compose-lab ───────────────────────────────────────────────────
mkdir -p $BASE/docker-compose-lab
cat > $BASE/docker-compose-lab/Dockerfile << 'DOCKERFILE'
FROM docker:24-dind
RUN apk add --no-cache bash curl nano docker-compose
RUN curl -fsSL https://github.com/tsl0922/ttyd/releases/download/1.7.4/ttyd.x86_64 \
    -o /usr/local/bin/ttyd && chmod +x /usr/local/bin/ttyd 2>/dev/null || true
COPY init.sh /usr/local/bin/lab-init.sh
COPY compose-exercise/ /home/labuser/compose-exercise/
RUN chmod +x /usr/local/bin/lab-init.sh
EXPOSE 7681
ENTRYPOINT ["ttyd","-p","7681","-W","bash","--","-c","dockerd &>/tmp/dockerd.log & sleep 3; bash /usr/local/bin/lab-init.sh; exec bash"]
DOCKERFILE

cat > $BASE/docker-compose-lab/init.sh << 'INIT'
#!/bin/bash
until docker info &>/dev/null; do sleep 1; done
echo "Exercise: complete the docker-compose.yml in ~/compose-exercise/"
echo "It should start a web app + redis + postgres"
INIT

mkdir -p $BASE/docker-compose-lab/compose-exercise
cat > $BASE/docker-compose-lab/compose-exercise/docker-compose.yml << 'YML'
version: '3.9'
services:
  web:
    image: nginx:alpine
    ports:
      - "8080:80"
    depends_on:
      - redis
  redis:
    image: redis:7-alpine
    # TODO: add a named volume for persistence
  # TODO: add a postgres service with environment variables
YML

# ── 3.4 docker-networking-lab ────────────────────────────────────────────────
mkdir -p $BASE/docker-networking-lab
cat > $BASE/docker-networking-lab/Dockerfile << 'DOCKERFILE'
FROM docker:24-dind
RUN apk add --no-cache bash curl nano
COPY init.sh /usr/local/bin/lab-init.sh
RUN chmod +x /usr/local/bin/lab-init.sh
EXPOSE 7681
ENTRYPOINT ["sh","-c","dockerd &>/tmp/dockerd.log & sleep 3; ttyd -p 7681 -W bash -- -c 'bash /usr/local/bin/lab-init.sh; exec bash'"]
DOCKERFILE

cat > $BASE/docker-networking-lab/init.sh << 'INIT'
#!/bin/bash
until docker info &>/dev/null; do sleep 1; done
echo "Tasks:"
echo "1. Create a custom bridge network called 'lab-net'"
echo "2. Run two alpine containers attached to lab-net"
echo "3. Ping between them by container name"
echo "4. Inspect network with: docker network inspect lab-net"
INIT

# ══════════════════════════════════════════════════════════════════════════════
# CATEGORY 4 — KUBERNETES BASICS
# ══════════════════════════════════════════════════════════════════════════════
# Uses k3s (lightweight Kubernetes) inside the container

# ── 4.1 k8s-kubectl-basics ───────────────────────────────────────────────────
mkdir -p $BASE/k8s-kubectl-basics
cat > $BASE/k8s-kubectl-basics/Dockerfile << 'DOCKERFILE'
FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y curl bash nano sudo \
    && rm -rf /var/lib/apt/lists/*
# kubectl
RUN curl -fsSL "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" \
    -o /usr/local/bin/kubectl && chmod +x /usr/local/bin/kubectl
# k3s for local cluster
RUN curl -fsSL https://get.k3s.io | sh -s - --write-kubeconfig-mode 644 || true
RUN curl -fsSL https://github.com/tsl0922/ttyd/releases/download/1.7.4/ttyd.x86_64 \
    -o /usr/local/bin/ttyd && chmod +x /usr/local/bin/ttyd
RUN useradd -m -u 1000 -s /bin/bash labuser \
    && echo "labuser ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
COPY init.sh /usr/local/bin/lab-init.sh
RUN chmod +x /usr/local/bin/lab-init.sh
USER labuser
WORKDIR /home/labuser
EXPOSE 7681
ENTRYPOINT ["ttyd","-p","7681","-W","bash","--","-c","sudo bash /usr/local/bin/lab-init.sh; exec bash"]
DOCKERFILE

cat > $BASE/k8s-kubectl-basics/init.sh << 'INIT'
#!/bin/bash
# Start k3s
k3s server --disable traefik &>/tmp/k3s.log &
echo "Starting Kubernetes cluster..."
until kubectl get nodes &>/dev/null 2>&1; do sleep 2; done
echo "Cluster ready!"
kubectl get nodes
echo ""
echo "Try: kubectl get pods --all-namespaces"
INIT

# ── 4.2 k8s-deployments ──────────────────────────────────────────────────────
mkdir -p $BASE/k8s-deployments
cat > $BASE/k8s-deployments/Dockerfile << 'DOCKERFILE'
FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y curl bash nano sudo \
    && rm -rf /var/lib/apt/lists/*
RUN curl -fsSL "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" \
    -o /usr/local/bin/kubectl && chmod +x /usr/local/bin/kubectl
RUN curl -fsSL https://github.com/tsl0922/ttyd/releases/download/1.7.4/ttyd.x86_64 \
    -o /usr/local/bin/ttyd && chmod +x /usr/local/bin/ttyd
RUN useradd -m -u 1000 -s /bin/bash labuser \
    && echo "labuser ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
COPY manifests/ /home/labuser/manifests/
COPY init.sh /usr/local/bin/lab-init.sh
RUN chmod +x /usr/local/bin/lab-init.sh
USER labuser
WORKDIR /home/labuser
EXPOSE 7681
ENTRYPOINT ["ttyd","-p","7681","-W","bash","--","-c","sudo bash /usr/local/bin/lab-init.sh; exec bash"]
DOCKERFILE

mkdir -p $BASE/k8s-deployments/manifests
cat > $BASE/k8s-deployments/manifests/deployment.yaml << 'YAML'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
spec:
  replicas: 1        # TODO: change to 3
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.24
        ports:
        - containerPort: 80
        # TODO: add resource requests and limits
YAML

cat > $BASE/k8s-deployments/init.sh << 'INIT'
#!/bin/bash
k3s server --disable traefik &>/tmp/k3s.log &
until kubectl get nodes &>/dev/null 2>&1; do sleep 2; done
echo "Cluster ready. Your manifests are in ~/manifests/"
echo "Task 1: Apply the deployment: kubectl apply -f manifests/deployment.yaml"
echo "Task 2: Scale to 3 replicas"
echo "Task 3: Perform a rolling update to nginx:1.25"
INIT

# ── 4.3 k8s-services ─────────────────────────────────────────────────────────
mkdir -p $BASE/k8s-services
cat > $BASE/k8s-services/Dockerfile << 'DOCKERFILE'
FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y curl bash nano sudo \
    && rm -rf /var/lib/apt/lists/*
RUN curl -fsSL "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" \
    -o /usr/local/bin/kubectl && chmod +x /usr/local/bin/kubectl
RUN curl -fsSL https://github.com/tsl0922/ttyd/releases/download/1.7.4/ttyd.x86_64 \
    -o /usr/local/bin/ttyd && chmod +x /usr/local/bin/ttyd
RUN useradd -m -u 1000 -s /bin/bash labuser \
    && echo "labuser ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
COPY init.sh /usr/local/bin/lab-init.sh
RUN chmod +x /usr/local/bin/lab-init.sh
USER labuser
WORKDIR /home/labuser
EXPOSE 7681
ENTRYPOINT ["ttyd","-p","7681","-W","bash","--","-c","sudo bash /usr/local/bin/lab-init.sh; exec bash"]
DOCKERFILE

cat > $BASE/k8s-services/init.sh << 'INIT'
#!/bin/bash
k3s server --disable traefik &>/tmp/k3s.log &
until kubectl get nodes &>/dev/null 2>&1; do sleep 2; done
kubectl create deployment web --image=nginx:alpine --replicas=2 &>/dev/null
echo "Cluster ready with a 'web' deployment running."
echo "Tasks:"
echo "1. Expose it with a ClusterIP service"
echo "2. Expose it with a NodePort service"
echo "3. Verify with: kubectl get svc"
INIT

# ── 4.4 k8s-configmaps-secrets ───────────────────────────────────────────────
mkdir -p $BASE/k8s-configmaps-secrets
cat > $BASE/k8s-configmaps-secrets/Dockerfile << 'DOCKERFILE'
FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y curl bash nano sudo \
    && rm -rf /var/lib/apt/lists/*
RUN curl -fsSL "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" \
    -o /usr/local/bin/kubectl && chmod +x /usr/local/bin/kubectl
RUN curl -fsSL https://github.com/tsl0922/ttyd/releases/download/1.7.4/ttyd.x86_64 \
    -o /usr/local/bin/ttyd && chmod +x /usr/local/bin/ttyd
RUN useradd -m -u 1000 -s /bin/bash labuser \
    && echo "labuser ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
COPY init.sh /usr/local/bin/lab-init.sh
RUN chmod +x /usr/local/bin/lab-init.sh
USER labuser
WORKDIR /home/labuser
EXPOSE 7681
ENTRYPOINT ["ttyd","-p","7681","-W","bash","--","-c","sudo bash /usr/local/bin/lab-init.sh; exec bash"]
DOCKERFILE

cat > $BASE/k8s-configmaps-secrets/init.sh << 'INIT'
#!/bin/bash
k3s server --disable traefik &>/tmp/k3s.log &
until kubectl get nodes &>/dev/null 2>&1; do sleep 2; done
echo "Tasks:"
echo "1. Create a ConfigMap with APP_ENV=production"
echo "2. Create a Secret with DB_PASSWORD=supersecret"
echo "3. Mount both into a pod and verify the values"
INIT

# ══════════════════════════════════════════════════════════════════════════════
# CATEGORY 5 — DATABASES
# ══════════════════════════════════════════════════════════════════════════════

# ── 5.1 db-postgres-basics ───────────────────────────────────────────────────
mkdir -p $BASE/db-postgres-basics
cat > $BASE/db-postgres-basics/Dockerfile << 'DOCKERFILE'
FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y \
    postgresql postgresql-client sudo nano \
    && rm -rf /var/lib/apt/lists/*
RUN curl -fsSL https://github.com/tsl0922/ttyd/releases/download/1.7.4/ttyd.x86_64 \
    -o /usr/local/bin/ttyd && chmod +x /usr/local/bin/ttyd
RUN useradd -m -u 1000 -s /bin/bash labuser \
    && echo "labuser ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
COPY init.sh /usr/local/bin/lab-init.sh
RUN chmod +x /usr/local/bin/lab-init.sh
USER labuser
WORKDIR /home/labuser
EXPOSE 7681
ENTRYPOINT ["ttyd","-p","7681","-W","bash","--","-c","sudo bash /usr/local/bin/lab-init.sh; exec bash"]
DOCKERFILE

cat > $BASE/db-postgres-basics/init.sh << 'INIT'
#!/bin/bash
sudo service postgresql start
sudo -u postgres psql -c "CREATE USER labuser WITH PASSWORD 'labpass' SUPERUSER;" 2>/dev/null || true
sudo -u postgres createdb labdb 2>/dev/null || true
psql -U labuser -d labdb << 'SQL'
CREATE TABLE IF NOT EXISTS employees (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  department TEXT NOT NULL,
  salary INTEGER NOT NULL,
  hired_at DATE DEFAULT CURRENT_DATE
);
INSERT INTO employees (name, department, salary) VALUES
  ('Alice', 'Engineering', 95000),
  ('Bob', 'Marketing', 72000),
  ('Carol', 'Engineering', 88000),
  ('Dave', 'HR', 65000),
  ('Eve', 'Engineering', 102000);
SQL
echo "PostgreSQL ready. Connect with: psql -U labuser -d labdb"
INIT

# ── 5.2 db-redis-basics ──────────────────────────────────────────────────────
mkdir -p $BASE/db-redis-basics
cat > $BASE/db-redis-basics/Dockerfile << 'DOCKERFILE'
FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y redis-server nano \
    && rm -rf /var/lib/apt/lists/*
RUN curl -fsSL https://github.com/tsl0922/ttyd/releases/download/1.7.4/ttyd.x86_64 \
    -o /usr/local/bin/ttyd && chmod +x /usr/local/bin/ttyd
RUN useradd -m -u 1000 -s /bin/bash labuser
COPY init.sh /usr/local/bin/lab-init.sh
RUN chmod +x /usr/local/bin/lab-init.sh
USER labuser
WORKDIR /home/labuser
EXPOSE 7681
ENTRYPOINT ["ttyd","-p","7681","-W","bash","--","-c","redis-server --daemonize yes; bash /usr/local/bin/lab-init.sh; exec bash"]
DOCKERFILE

cat > $BASE/db-redis-basics/init.sh << 'INIT'
#!/bin/bash
sleep 1
redis-cli SET welcome "Hello from Redis lab!"
redis-cli HSET user:1 name "Alice" role "admin" score 95
redis-cli LPUSH tasks "deploy" "test" "build" "plan"
redis-cli ZADD leaderboard 100 "alice" 85 "bob" 92 "carol"
echo "Redis ready. Try: redis-cli PING"
echo "Sample data loaded — strings, hashes, lists, sorted sets"
INIT

# ── 5.3 db-mysql-basics ──────────────────────────────────────────────────────
mkdir -p $BASE/db-mysql-basics
cat > $BASE/db-mysql-basics/Dockerfile << 'DOCKERFILE'
FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive
ENV MYSQL_ROOT_PASSWORD=labpass
RUN apt-get update && apt-get install -y mysql-server nano \
    && rm -rf /var/lib/apt/lists/*
RUN curl -fsSL https://github.com/tsl0922/ttyd/releases/download/1.7.4/ttyd.x86_64 \
    -o /usr/local/bin/ttyd && chmod +x /usr/local/bin/ttyd
RUN useradd -m -u 1000 -s /bin/bash labuser
COPY init.sh /usr/local/bin/lab-init.sh
RUN chmod +x /usr/local/bin/lab-init.sh
USER labuser
WORKDIR /home/labuser
EXPOSE 7681
ENTRYPOINT ["ttyd","-p","7681","-W","bash","--","-c","sudo service mysql start; bash /usr/local/bin/lab-init.sh; exec bash"]
DOCKERFILE

cat > $BASE/db-mysql-basics/init.sh << 'INIT'
#!/bin/bash
sleep 2
mysql -u root -plabpass << 'SQL'
CREATE DATABASE IF NOT EXISTS shopdb;
USE shopdb;
CREATE TABLE IF NOT EXISTS products (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100),
  price DECIMAL(10,2),
  stock INT
);
INSERT INTO products (name, price, stock) VALUES
  ('Laptop', 999.99, 50),
  ('Mouse', 29.99, 200),
  ('Keyboard', 79.99, 150);
CREATE USER IF NOT EXISTS 'labuser'@'localhost' IDENTIFIED BY 'labpass';
GRANT ALL ON shopdb.* TO 'labuser'@'localhost';
SQL
echo "MySQL ready. Connect: mysql -u labuser -plabpass shopdb"
INIT

# ── 5.4 db-mongodb-basics ────────────────────────────────────────────────────
mkdir -p $BASE/db-mongodb-basics
cat > $BASE/db-mongodb-basics/Dockerfile << 'DOCKERFILE'
FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y gnupg curl nano \
    && curl -fsSL https://www.mongodb.org/static/pgp/server-7.0.asc | gpg -o /usr/share/keyrings/mongodb-server-7.0.gpg --dearmor \
    && echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse" > /etc/apt/sources.list.d/mongodb-org-7.0.list \
    && apt-get update && apt-get install -y mongodb-org \
    && rm -rf /var/lib/apt/lists/*
RUN curl -fsSL https://github.com/tsl0922/ttyd/releases/download/1.7.4/ttyd.x86_64 \
    -o /usr/local/bin/ttyd && chmod +x /usr/local/bin/ttyd
RUN useradd -m -u 1000 -s /bin/bash labuser \
    && mkdir -p /data/db && chown labuser:labuser /data/db
COPY init.sh /usr/local/bin/lab-init.sh
RUN chmod +x /usr/local/bin/lab-init.sh
USER labuser
WORKDIR /home/labuser
EXPOSE 7681
ENTRYPOINT ["ttyd","-p","7681","-W","bash","--","-c","mongod --fork --logpath /tmp/mongo.log; bash /usr/local/bin/lab-init.sh; exec bash"]
DOCKERFILE

cat > $BASE/db-mongodb-basics/init.sh << 'INIT'
#!/bin/bash
sleep 2
mongosh --quiet << 'JS'
use labdb
db.users.insertMany([
  { name: "Alice", role: "admin", scores: [95, 88, 91] },
  { name: "Bob", role: "student", scores: [72, 65, 78] },
  { name: "Carol", role: "student", scores: [88, 92, 85] }
])
db.products.insertMany([
  { name: "Laptop", price: 999, tags: ["electronics", "computing"] },
  { name: "Desk", price: 299, tags: ["furniture", "office"] }
])
JS
echo "MongoDB ready. Connect: mongosh labdb"
INIT

# ══════════════════════════════════════════════════════════════════════════════
# CATEGORY 6 — CI/CD BASICS
# ══════════════════════════════════════════════════════════════════════════════

# ── 6.1 cicd-git-workflows ───────────────────────────────────────────────────
mkdir -p $BASE/cicd-git-workflows
cat > $BASE/cicd-git-workflows/Dockerfile << 'DOCKERFILE'
FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y git nano bash \
    && rm -rf /var/lib/apt/lists/*
RUN curl -fsSL https://github.com/tsl0922/ttyd/releases/download/1.7.4/ttyd.x86_64 \
    -o /usr/local/bin/ttyd && chmod +x /usr/local/bin/ttyd
RUN useradd -m -u 1000 -s /bin/bash labuser
COPY init.sh /usr/local/bin/lab-init.sh
RUN chmod +x /usr/local/bin/lab-init.sh
USER labuser
WORKDIR /home/labuser
EXPOSE 7681
ENTRYPOINT ["ttyd","-p","7681","-W","bash","--","-c","bash /usr/local/bin/lab-init.sh; exec bash"]
DOCKERFILE

cat > $BASE/cicd-git-workflows/init.sh << 'INIT'
#!/bin/bash
git config --global user.email "labuser@lab.local"
git config --global user.name "Lab User"
git config --global init.defaultBranch main
mkdir -p ~/git-lab && cd ~/git-lab
git init && git commit --allow-empty -m "Initial commit"
git checkout -b feature/add-login
echo "function login() { return true; }" > auth.js
git add . && git commit -m "Add login function"
git checkout main
echo "Tasks: merge feature branch, resolve conflict, tag a release"
INIT

# ── 6.2 cicd-github-actions ──────────────────────────────────────────────────
mkdir -p $BASE/cicd-github-actions
cat > $BASE/cicd-github-actions/Dockerfile << 'DOCKERFILE'
FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y git nano bash python3 curl \
    && rm -rf /var/lib/apt/lists/*
RUN curl -fsSL https://github.com/tsl0922/ttyd/releases/download/1.7.4/ttyd.x86_64 \
    -o /usr/local/bin/ttyd && chmod +x /usr/local/bin/ttyd
RUN useradd -m -u 1000 -s /bin/bash labuser
COPY init.sh /usr/local/bin/lab-init.sh
COPY workflow-template/ /home/labuser/my-project/
RUN chmod +x /usr/local/bin/lab-init.sh && chown -R labuser:labuser /home/labuser
USER labuser
WORKDIR /home/labuser
EXPOSE 7681
ENTRYPOINT ["ttyd","-p","7681","-W","bash","--","-c","bash /usr/local/bin/lab-init.sh; exec bash"]
DOCKERFILE

mkdir -p $BASE/cicd-github-actions/workflow-template/.github/workflows
cat > $BASE/cicd-github-actions/workflow-template/.github/workflows/ci.yml << 'YML'
# TODO: Complete this GitHub Actions workflow
name: CI Pipeline
on:
  push:
    branches: [main]
  pull_request:

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      # TODO: Add a step to set up Python 3.11
      # TODO: Add a step to install dependencies from requirements.txt
      # TODO: Add a step to run: python -m pytest
YML

cat > $BASE/cicd-github-actions/init.sh << 'INIT'
#!/bin/bash
git config --global user.email "lab@lab.local" && git config --global user.name "Lab User"
cd ~/my-project && git init && git add . && git commit -m "Initial project"
echo "Task: complete .github/workflows/ci.yml"
echo "Reference: https://docs.github.com/en/actions"
INIT

# ── 6.3 cicd-docker-pipeline ─────────────────────────────────────────────────
mkdir -p $BASE/cicd-docker-pipeline
cat > $BASE/cicd-docker-pipeline/Dockerfile << 'DOCKERFILE'
FROM docker:24-dind
RUN apk add --no-cache bash git nano curl
COPY init.sh /usr/local/bin/lab-init.sh
COPY app/ /home/labuser/app/
RUN chmod +x /usr/local/bin/lab-init.sh && mkdir -p /home/labuser
EXPOSE 7681
ENTRYPOINT ["sh","-c","dockerd &>/tmp/dockerd.log & sleep 3; ttyd -p 7681 -W bash -- -c 'bash /usr/local/bin/lab-init.sh; exec bash'"]
DOCKERFILE

mkdir -p $BASE/cicd-docker-pipeline/app
cat > $BASE/cicd-docker-pipeline/app/app.py << 'PY'
print("Hello from the pipeline!")
PY
cat > $BASE/cicd-docker-pipeline/init.sh << 'INIT'
#!/bin/bash
until docker info &>/dev/null; do sleep 1; done
echo "Task: Write a Dockerfile for ~/app/app.py"
echo "Then: docker build -t my-pipeline-app . && docker run my-pipeline-app"
INIT

# ── 6.4 cicd-jenkins-basics ──────────────────────────────────────────────────
mkdir -p $BASE/cicd-jenkins-basics
cat > $BASE/cicd-jenkins-basics/Dockerfile << 'DOCKERFILE'
FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y nano bash curl git \
    && rm -rf /var/lib/apt/lists/*
RUN curl -fsSL https://github.com/tsl0922/ttyd/releases/download/1.7.4/ttyd.x86_64 \
    -o /usr/local/bin/ttyd && chmod +x /usr/local/bin/ttyd
RUN useradd -m -u 1000 -s /bin/bash labuser
COPY init.sh /usr/local/bin/lab-init.sh
RUN chmod +x /usr/local/bin/lab-init.sh
USER labuser
WORKDIR /home/labuser
EXPOSE 7681
ENTRYPOINT ["ttyd","-p","7681","-W","bash","--","-c","bash /usr/local/bin/lab-init.sh; exec bash"]
DOCKERFILE

cat > $BASE/cicd-jenkins-basics/init.sh << 'INIT'
#!/bin/bash
mkdir -p ~/jenkins-lab
cat > ~/jenkins-lab/Jenkinsfile << 'JF'
pipeline {
    agent any
    stages {
        stage('Build') {
            steps {
                echo 'Building application...'
                sh 'echo build complete'
            }
        }
        stage('Test') {
            steps {
                echo 'Running tests...'
                // TODO: add actual test command
            }
        }
        stage('Deploy') {
            steps {
                echo 'Deploying...'
                // TODO: add deploy steps
            }
        }
    }
}
JF
echo "Jenkinsfile created in ~/jenkins-lab/"
echo "Task: Complete the Test and Deploy stages"
INIT

# ══════════════════════════════════════════════════════════════════════════════
# CATEGORY 7 — INFRASTRUCTURE AS CODE
# ══════════════════════════════════════════════════════════════════════════════

# ── 7.1 iac-terraform-basics ─────────────────────────────────────────────────
mkdir -p $BASE/iac-terraform-basics
cat > $BASE/iac-terraform-basics/Dockerfile << 'DOCKERFILE'
FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y curl unzip nano bash \
    && curl -fsSL https://releases.hashicorp.com/terraform/1.7.4/terraform_1.7.4_linux_amd64.zip -o tf.zip \
    && unzip tf.zip -d /usr/local/bin/ && rm tf.zip \
    && rm -rf /var/lib/apt/lists/*
RUN curl -fsSL https://github.com/tsl0922/ttyd/releases/download/1.7.4/ttyd.x86_64 \
    -o /usr/local/bin/ttyd && chmod +x /usr/local/bin/ttyd
RUN useradd -m -u 1000 -s /bin/bash labuser
COPY exercises/ /home/labuser/exercises/
COPY init.sh /usr/local/bin/lab-init.sh
RUN chmod +x /usr/local/bin/lab-init.sh && chown -R labuser:labuser /home/labuser
USER labuser
WORKDIR /home/labuser
EXPOSE 7681
ENTRYPOINT ["ttyd","-p","7681","-W","bash","--","-c","bash /usr/local/bin/lab-init.sh; exec bash"]
DOCKERFILE

mkdir -p $BASE/iac-terraform-basics/exercises
cat > $BASE/iac-terraform-basics/exercises/main.tf << 'TF'
# Terraform Basics Exercise
# Using the 'local' provider (no cloud account needed)
terraform {
  required_providers {
    local = { source = "hashicorp/local" }
  }
}

# TODO: Create a local_file resource that writes "Hello Terraform!" to hello.txt
# resource "local_file" "hello" { ... }

# TODO: Add an output that shows the filename
# output "filename" { ... }
TF

cat > $BASE/iac-terraform-basics/init.sh << 'INIT'
#!/bin/bash
echo "Terraform $(terraform version -json | python3 -c 'import sys,json; print(json.load(sys.stdin)[\"terraform_version\"])')"
echo "Exercises are in ~/exercises/"
echo "Tasks:"
echo "1. Complete main.tf"
echo "2. terraform init"
echo "3. terraform plan"
echo "4. terraform apply"
INIT

# ── 7.2 iac-terraform-modules ────────────────────────────────────────────────
mkdir -p $BASE/iac-terraform-modules/exercises/modules/file-generator
cat > $BASE/iac-terraform-modules/exercises/modules/file-generator/main.tf << 'TF'
variable "filename" { type = string }
variable "content"  { type = string }

resource "local_file" "generated" {
  filename = var.filename
  content  = var.content
}

output "created_file" { value = local_file.generated.filename }
TF

cat > $BASE/iac-terraform-modules/exercises/main.tf << 'TF'
terraform {
  required_providers {
    local = { source = "hashicorp/local" }
  }
}

# TODO: Call the file-generator module twice
# to create two different files with different content
# module "file1" {
#   source   = "./modules/file-generator"
#   filename = "..."
#   content  = "..."
# }
TF

cat > $BASE/iac-terraform-modules/Dockerfile << 'DOCKERFILE'
FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y curl unzip nano bash \
    && curl -fsSL https://releases.hashicorp.com/terraform/1.7.4/terraform_1.7.4_linux_amd64.zip -o tf.zip \
    && unzip tf.zip -d /usr/local/bin/ && rm tf.zip && rm -rf /var/lib/apt/lists/*
RUN curl -fsSL https://github.com/tsl0922/ttyd/releases/download/1.7.4/ttyd.x86_64 \
    -o /usr/local/bin/ttyd && chmod +x /usr/local/bin/ttyd
RUN useradd -m -u 1000 -s /bin/bash labuser
COPY exercises/ /home/labuser/exercises/
RUN chown -R labuser:labuser /home/labuser
USER labuser
WORKDIR /home/labuser
EXPOSE 7681
ENTRYPOINT ["ttyd","-p","7681","-W","bash"]
DOCKERFILE

# ── 7.3 iac-ansible-basics ───────────────────────────────────────────────────
mkdir -p $BASE/iac-ansible-basics
cat > $BASE/iac-ansible-basics/Dockerfile << 'DOCKERFILE'
FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y ansible nano bash python3 \
    && rm -rf /var/lib/apt/lists/*
RUN curl -fsSL https://github.com/tsl0922/ttyd/releases/download/1.7.4/ttyd.x86_64 \
    -o /usr/local/bin/ttyd && chmod +x /usr/local/bin/ttyd
RUN useradd -m -u 1000 -s /bin/bash labuser
COPY playbooks/ /home/labuser/playbooks/
COPY init.sh /usr/local/bin/lab-init.sh
RUN chmod +x /usr/local/bin/lab-init.sh && chown -R labuser:labuser /home/labuser
USER labuser
WORKDIR /home/labuser
EXPOSE 7681
ENTRYPOINT ["ttyd","-p","7681","-W","bash","--","-c","bash /usr/local/bin/lab-init.sh; exec bash"]
DOCKERFILE

mkdir -p $BASE/iac-ansible-basics/playbooks
cat > $BASE/iac-ansible-basics/playbooks/setup.yml << 'YML'
---
- name: Basic Setup Playbook
  hosts: localhost
  connection: local
  tasks:
    - name: Create a directory
      file:
        path: /tmp/ansible-output
        state: directory
        mode: '0755'

    # TODO: Add a task to create a file inside /tmp/ansible-output/
    # with content "Ansible was here!"

    # TODO: Add a task to install a package (use 'become: yes' for apt)
YML

cat > $BASE/iac-ansible-basics/init.sh << 'INIT'
#!/bin/bash
echo "Ansible $(ansible --version | head -1)"
echo "Playbooks are in ~/playbooks/"
echo "Run with: ansible-playbook playbooks/setup.yml"
INIT

# ── 7.4 iac-localstack-aws ───────────────────────────────────────────────────
mkdir -p $BASE/iac-localstack-aws
cat > $BASE/iac-localstack-aws/Dockerfile << 'DOCKERFILE'
FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y python3 python3-pip curl nano bash \
    && pip3 install awscli localstack \
    && rm -rf /var/lib/apt/lists/*
RUN curl -fsSL https://github.com/tsl0922/ttyd/releases/download/1.7.4/ttyd.x86_64 \
    -o /usr/local/bin/ttyd && chmod +x /usr/local/bin/ttyd
RUN useradd -m -u 1000 -s /bin/bash labuser
COPY init.sh /usr/local/bin/lab-init.sh
RUN chmod +x /usr/local/bin/lab-init.sh
USER labuser
WORKDIR /home/labuser
EXPOSE 7681
ENTRYPOINT ["ttyd","-p","7681","-W","bash","--","-c","localstack start -d; bash /usr/local/bin/lab-init.sh; exec bash"]
DOCKERFILE

cat > $BASE/iac-localstack-aws/init.sh << 'INIT'
#!/bin/bash
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test
export AWS_DEFAULT_REGION=us-east-1
alias aws='aws --endpoint-url http://localhost:4566'
echo "export AWS_ACCESS_KEY_ID=test" >> ~/.bashrc
echo "export AWS_SECRET_ACCESS_KEY=test" >> ~/.bashrc
echo "export AWS_DEFAULT_REGION=us-east-1" >> ~/.bashrc
echo "alias aws='aws --endpoint-url http://localhost:4566'" >> ~/.bashrc
echo "LocalStack AWS simulation ready"
echo "Try: aws s3 mb s3://my-bucket"
INIT

# ══════════════════════════════════════════════════════════════════════════════
# CATEGORY 8 — OBSERVABILITY & MONITORING
# ══════════════════════════════════════════════════════════════════════════════

# ── 8.1 obs-prometheus-basics ────────────────────────────────────────────────
mkdir -p $BASE/obs-prometheus-basics
cat > $BASE/obs-prometheus-basics/Dockerfile << 'DOCKERFILE'
FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y curl bash nano python3 \
    && rm -rf /var/lib/apt/lists/*
RUN curl -fsSL https://github.com/prometheus/prometheus/releases/download/v2.50.1/prometheus-2.50.1.linux-amd64.tar.gz \
    | tar xz -C /opt/ && ln -s /opt/prometheus-2.50.1.linux-amd64 /opt/prometheus
RUN curl -fsSL https://github.com/tsl0922/ttyd/releases/download/1.7.4/ttyd.x86_64 \
    -o /usr/local/bin/ttyd && chmod +x /usr/local/bin/ttyd
RUN useradd -m -u 1000 -s /bin/bash labuser
COPY prometheus.yml /etc/prometheus/prometheus.yml
COPY init.sh /usr/local/bin/lab-init.sh
RUN chmod +x /usr/local/bin/lab-init.sh
USER labuser
WORKDIR /home/labuser
EXPOSE 7681 9090
ENTRYPOINT ["ttyd","-p","7681","-W","bash","--","-c","bash /usr/local/bin/lab-init.sh; exec bash"]
DOCKERFILE

cat > $BASE/obs-prometheus-basics/prometheus.yml << 'YML'
global:
  scrape_interval: 15s
scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']
  - job_name: 'node'
    static_configs:
      - targets: ['localhost:9100']
YML

cat > $BASE/obs-prometheus-basics/init.sh << 'INIT'
#!/bin/bash
/opt/prometheus/prometheus --config.file=/etc/prometheus/prometheus.yml \
  --storage.tsdb.path=/tmp/prometheus-data &>/tmp/prometheus.log &
sleep 2
echo "Prometheus running on http://localhost:9090"
echo "Tasks:"
echo "1. Open: curl http://localhost:9090/api/v1/status/config"
echo "2. Try PromQL: curl 'http://localhost:9090/api/v1/query?query=up'"
INIT

# ── 8.2 obs-log-analysis ─────────────────────────────────────────────────────
mkdir -p $BASE/obs-log-analysis
cat > $BASE/obs-log-analysis/Dockerfile << 'DOCKERFILE'
FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y bash gawk sed grep nano \
    && rm -rf /var/lib/apt/lists/*
RUN curl -fsSL https://github.com/tsl0922/ttyd/releases/download/1.7.4/ttyd.x86_64 \
    -o /usr/local/bin/ttyd && chmod +x /usr/local/bin/ttyd
RUN useradd -m -u 1000 -s /bin/bash labuser
COPY init.sh /usr/local/bin/lab-init.sh
RUN chmod +x /usr/local/bin/lab-init.sh
USER labuser
WORKDIR /home/labuser
EXPOSE 7681
ENTRYPOINT ["ttyd","-p","7681","-W","bash","--","-c","bash /usr/local/bin/lab-init.sh; exec bash"]
DOCKERFILE

cat > $BASE/obs-log-analysis/init.sh << 'INIT'
#!/bin/bash
mkdir -p ~/logs
python3 -c "
import random, datetime
levels = ['INFO','WARN','ERROR','DEBUG']
services = ['api','worker','db','cache']
base = datetime.datetime(2026,3,1,10,0,0)
with open('/home/labuser/logs/app.log','w') as f:
    for i in range(200):
        ts = base + datetime.timedelta(seconds=i*17)
        lvl = random.choices(levels, weights=[60,20,10,10])[0]
        svc = random.choice(services)
        msg = {'INFO':'Request processed','WARN':'High memory usage',
               'ERROR':'Connection refused','DEBUG':'Cache hit'}[lvl]
        f.write(f'{ts.strftime(\"%Y-%m-%d %H:%M:%S\")} [{lvl}] {svc}: {msg}\n')
"
echo "200 log lines generated in ~/logs/app.log"
echo "Tasks: count ERRORs, extract unique services, find peak error times"
INIT

# ── 8.3 obs-healthchecks ─────────────────────────────────────────────────────
mkdir -p $BASE/obs-healthchecks
cat > $BASE/obs-healthchecks/Dockerfile << 'DOCKERFILE'
FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y bash curl python3 nano \
    && rm -rf /var/lib/apt/lists/*
RUN curl -fsSL https://github.com/tsl0922/ttyd/releases/download/1.7.4/ttyd.x86_64 \
    -o /usr/local/bin/ttyd && chmod +x /usr/local/bin/ttyd
RUN useradd -m -u 1000 -s /bin/bash labuser
COPY init.sh /usr/local/bin/lab-init.sh
COPY app.py /home/labuser/app.py
RUN chmod +x /usr/local/bin/lab-init.sh && chown labuser:labuser /home/labuser/app.py
USER labuser
WORKDIR /home/labuser
EXPOSE 7681 8080
ENTRYPOINT ["ttyd","-p","7681","-W","bash","--","-c","bash /usr/local/bin/lab-init.sh; exec bash"]
DOCKERFILE

cat > $BASE/obs-healthchecks/app.py << 'PY'
from http.server import HTTPServer, BaseHTTPRequestHandler
import json, time

start_time = time.time()

class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == '/health':
            self.send_response(200)
            self.send_header('Content-Type','application/json')
            self.end_headers()
            self.wfile.write(json.dumps({"status":"ok","uptime":int(time.time()-start_time)}).encode())
        elif self.path == '/ready':
            self.send_response(200)
            self.send_header('Content-Type','application/json')
            self.end_headers()
            self.wfile.write(json.dumps({"status":"ready"}).encode())
        else:
            self.send_response(404)
            self.end_headers()
    def log_message(self, *args): pass

HTTPServer(("0.0.0.0", 8080), Handler).serve_forever()
PY

cat > $BASE/obs-healthchecks/init.sh << 'INIT'
#!/bin/bash
python3 ~/app.py &
sleep 1
echo "App running on port 8080"
echo "Tasks:"
echo "1. curl http://localhost:8080/health"
echo "2. curl http://localhost:8080/ready"
echo "3. Write a bash script that polls /health every 5s"
INIT

# ══════════════════════════════════════════════════════════════════════════════
# CATEGORY 9 — SECURITY BASICS
# ══════════════════════════════════════════════════════════════════════════════

# ── 9.1 security-tls-basics ──────────────────────────────────────────────────
mkdir -p $BASE/security-tls-basics
cat > $BASE/security-tls-basics/Dockerfile << 'DOCKERFILE'
FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y openssl curl bash nano \
    && rm -rf /var/lib/apt/lists/*
RUN curl -fsSL https://github.com/tsl0922/ttyd/releases/download/1.7.4/ttyd.x86_64 \
    -o /usr/local/bin/ttyd && chmod +x /usr/local/bin/ttyd
RUN useradd -m -u 1000 -s /bin/bash labuser
COPY init.sh /usr/local/bin/lab-init.sh
RUN chmod +x /usr/local/bin/lab-init.sh
USER labuser
WORKDIR /home/labuser
EXPOSE 7681
ENTRYPOINT ["ttyd","-p","7681","-W","bash","--","-c","bash /usr/local/bin/lab-init.sh; exec bash"]
DOCKERFILE

cat > $BASE/security-tls-basics/init.sh << 'INIT'
#!/bin/bash
mkdir -p ~/tls-lab
echo "Tasks:"
echo "1. Generate a self-signed cert:"
echo "   openssl req -x509 -newkey rsa:2048 -keyout ~/tls-lab/key.pem -out ~/tls-lab/cert.pem -days 365 -nodes"
echo "2. Inspect it: openssl x509 -in ~/tls-lab/cert.pem -text -noout"
echo "3. Check a real cert: openssl s_client -connect google.com:443 </dev/null"
INIT

# ── 9.2 security-linux-hardening ─────────────────────────────────────────────
mkdir -p $BASE/security-linux-hardening
cat > $BASE/security-linux-hardening/Dockerfile << 'DOCKERFILE'
FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y bash sudo nano ufw fail2ban \
    && rm -rf /var/lib/apt/lists/*
RUN curl -fsSL https://github.com/tsl0922/ttyd/releases/download/1.7.4/ttyd.x86_64 \
    -o /usr/local/bin/ttyd && chmod +x /usr/local/bin/ttyd
RUN useradd -m -u 1000 -s /bin/bash labuser \
    && echo "labuser ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
# Plant intentional misconfigurations to fix
RUN echo "PermitRootLogin yes" >> /etc/ssh/sshd_config 2>/dev/null || true
RUN echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config 2>/dev/null || true
COPY init.sh /usr/local/bin/lab-init.sh
RUN chmod +x /usr/local/bin/lab-init.sh
USER labuser
WORKDIR /home/labuser
EXPOSE 7681
ENTRYPOINT ["ttyd","-p","7681","-W","bash","--","-c","bash /usr/local/bin/lab-init.sh; exec bash"]
DOCKERFILE

cat > $BASE/security-linux-hardening/init.sh << 'INIT'
#!/bin/bash
echo "Security hardening tasks:"
echo "1. Find world-writable files: find / -perm -o+w -type f 2>/dev/null | grep -v proc"
echo "2. Check for SUID binaries: find / -perm -4000 2>/dev/null"
echo "3. Review /etc/passwd for unexpected users: cat /etc/passwd"
echo "4. Check listening ports: ss -tlnp"
INIT

# ── 9.3 security-secrets-vault ───────────────────────────────────────────────
mkdir -p $BASE/security-secrets-vault
cat > $BASE/security-secrets-vault/Dockerfile << 'DOCKERFILE'
FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y curl unzip nano bash \
    && curl -fsSL https://releases.hashicorp.com/vault/1.15.6/vault_1.15.6_linux_amd64.zip -o vault.zip \
    && unzip vault.zip -d /usr/local/bin/ && rm vault.zip \
    && rm -rf /var/lib/apt/lists/*
RUN curl -fsSL https://github.com/tsl0922/ttyd/releases/download/1.7.4/ttyd.x86_64 \
    -o /usr/local/bin/ttyd && chmod +x /usr/local/bin/ttyd
RUN useradd -m -u 1000 -s /bin/bash labuser
COPY init.sh /usr/local/bin/lab-init.sh
RUN chmod +x /usr/local/bin/lab-init.sh
USER labuser
WORKDIR /home/labuser
EXPOSE 7681 8200
ENTRYPOINT ["ttyd","-p","7681","-W","bash","--","-c","bash /usr/local/bin/lab-init.sh; exec bash"]
DOCKERFILE

cat > $BASE/security-secrets-vault/init.sh << 'INIT'
#!/bin/bash
export VAULT_DEV_ROOT_TOKEN_ID=root
export VAULT_ADDR=http://127.0.0.1:8200
vault server -dev -dev-root-token-id=root &>/tmp/vault.log &
sleep 2
echo "export VAULT_ADDR=http://127.0.0.1:8200" >> ~/.bashrc
echo "export VAULT_TOKEN=root" >> ~/.bashrc
vault status
vault kv put secret/myapp db_password=supersecret api_key=abc123
echo "Vault ready. Tasks:"
echo "1. vault kv get secret/myapp"
echo "2. vault kv put secret/mydb username=admin password=changeme"
echo "3. vault kv list secret/"
INIT

# ── 9.4 security-container-scanning ─────────────────────────────────────────
mkdir -p $BASE/security-container-scanning
cat > $BASE/security-container-scanning/Dockerfile << 'DOCKERFILE'
FROM docker:24-dind
RUN apk add --no-cache bash curl nano
RUN curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin
COPY init.sh /usr/local/bin/lab-init.sh
RUN chmod +x /usr/local/bin/lab-init.sh
EXPOSE 7681
ENTRYPOINT ["sh","-c","dockerd &>/tmp/dockerd.log & sleep 3; ttyd -p 7681 -W bash -- -c 'bash /usr/local/bin/lab-init.sh; exec bash'"]
DOCKERFILE

cat > $BASE/security-container-scanning/init.sh << 'INIT'
#!/bin/bash
until docker info &>/dev/null; do sleep 1; done
echo "Trivy container scanner ready"
echo "Tasks:"
echo "1. Scan an image: trivy image alpine:latest"
echo "2. Scan for critical only: trivy image --severity CRITICAL nginx:1.20"
echo "3. Scan a Dockerfile: trivy config ."
INIT

# ══════════════════════════════════════════════════════════════════════════════
# CATEGORY 10 — PYTHON FOR DEVOPS
# ══════════════════════════════════════════════════════════════════════════════

# ── 10.1 python-automation ───────────────────────────────────────────────────
mkdir -p $BASE/python-automation
cat > $BASE/python-automation/Dockerfile << 'DOCKERFILE'
FROM python:3.11-slim
RUN apt-get update && apt-get install -y bash nano curl \
    && pip install requests pyyaml \
    && rm -rf /var/lib/apt/lists/*
RUN curl -fsSL https://github.com/tsl0922/ttyd/releases/download/1.7.4/ttyd.x86_64 \
    -o /usr/local/bin/ttyd && chmod +x /usr/local/bin/ttyd
RUN useradd -m -u 1000 -s /bin/bash labuser
COPY exercises/ /home/labuser/exercises/
COPY init.sh /usr/local/bin/lab-init.sh
RUN chmod +x /usr/local/bin/lab-init.sh && chown -R labuser:labuser /home/labuser
USER labuser
WORKDIR /home/labuser
EXPOSE 7681
ENTRYPOINT ["ttyd","-p","7681","-W","bash","--","-c","bash /usr/local/bin/lab-init.sh; exec bash"]
DOCKERFILE

mkdir -p $BASE/python-automation/exercises
cat > $BASE/python-automation/exercises/exercise1.py << 'PY'
"""
Exercise 1: File Operations
Task: Write a script that:
1. Reads all .txt files in a directory
2. Counts total words across all files
3. Writes a summary to output.txt
"""
import os

def count_words_in_file(filepath):
    # TODO: implement this
    pass

def summarize_directory(directory, output_file):
    # TODO: implement this
    pass

if __name__ == "__main__":
    summarize_directory("./data", "./output.txt")
    print("Done! Check output.txt")
PY

cat > $BASE/python-automation/exercises/exercise2.py << 'PY'
"""
Exercise 2: API Client
Task: Use the requests library to:
1. Fetch data from https://jsonplaceholder.typicode.com/posts
2. Filter posts by userId=1
3. Print each post's title
"""
import requests

def get_posts_by_user(user_id):
    # TODO: implement this
    pass

if __name__ == "__main__":
    posts = get_posts_by_user(1)
    print(f"Found {len(posts)} posts")
PY

cat > $BASE/python-automation/init.sh << 'INIT'
#!/bin/bash
mkdir -p ~/exercises/data
for i in 1 2 3; do
  echo "This is sample file $i with some words in it" > ~/exercises/data/file$i.txt
done
echo "Python exercises ready in ~/exercises/"
echo "Run: python3 exercises/exercise1.py"
INIT

# ── 10.2 python-cli-tools ────────────────────────────────────────────────────
mkdir -p $BASE/python-cli-tools
cat > $BASE/python-cli-tools/Dockerfile << 'DOCKERFILE'
FROM python:3.11-slim
RUN apt-get update && apt-get install -y bash nano \
    && pip install click rich argparse \
    && rm -rf /var/lib/apt/lists/*
RUN curl -fsSL https://github.com/tsl0922/ttyd/releases/download/1.7.4/ttyd.x86_64 \
    -o /usr/local/bin/ttyd && chmod +x /usr/local/bin/ttyd
RUN useradd -m -u 1000 -s /bin/bash labuser
COPY exercises/ /home/labuser/exercises/
RUN chown -R labuser:labuser /home/labuser
USER labuser
WORKDIR /home/labuser
EXPOSE 7681
ENTRYPOINT ["ttyd","-p","7681","-W","bash"]
DOCKERFILE

mkdir -p $BASE/python-cli-tools/exercises
cat > $BASE/python-cli-tools/exercises/cli_tool.py << 'PY'
"""
Build a CLI tool using Click that:
1. Has a command 'greet' that takes a --name argument
2. Has a command 'count' that counts lines in a file
3. Has a --verbose flag that shows extra output
"""
import click

@click.group()
def cli():
    pass

@cli.command()
@click.option('--name', default='World', help='Name to greet')
def greet(name):
    # TODO: implement
    pass

@cli.command()
@click.argument('filename')
@click.option('--verbose', is_flag=True)
def count(filename, verbose):
    # TODO: implement
    pass

if __name__ == '__main__':
    cli()
PY

# ── 10.3 python-yaml-json ────────────────────────────────────────────────────
mkdir -p $BASE/python-yaml-json
cat > $BASE/python-yaml-json/Dockerfile << 'DOCKERFILE'
FROM python:3.11-slim
RUN apt-get update && apt-get install -y bash nano \
    && pip install pyyaml \
    && rm -rf /var/lib/apt/lists/*
RUN curl -fsSL https://github.com/tsl0922/ttyd/releases/download/1.7.4/ttyd.x86_64 \
    -o /usr/local/bin/ttyd && chmod +x /usr/local/bin/ttyd
RUN useradd -m -u 1000 -s /bin/bash labuser
COPY exercises/ /home/labuser/exercises/
RUN chown -R labuser:labuser /home/labuser
USER labuser
WORKDIR /home/labuser
EXPOSE 7681
ENTRYPOINT ["ttyd","-p","7681","-W","bash"]
DOCKERFILE

mkdir -p $BASE/python-yaml-json/exercises
cat > $BASE/python-yaml-json/exercises/config.yaml << 'YML'
app:
  name: my-service
  version: "1.2.3"
  debug: false
database:
  host: localhost
  port: 5432
  name: appdb
  pool_size: 10
servers:
  - name: web-01
    ip: 10.0.0.1
    roles: [web, cache]
  - name: db-01
    ip: 10.0.0.2
    roles: [database]
YML

cat > $BASE/python-yaml-json/exercises/parse_config.py << 'PY'
"""
Tasks:
1. Load config.yaml and print the app version
2. List all server names and their IPs
3. Convert the entire config to JSON and save to config.json
4. Add a new server to the YAML and save it back
"""
import yaml, json

with open('exercises/config.yaml') as f:
    config = yaml.safe_load(f)

# TODO: complete the tasks above
PY

# ── 10.4 python-devops-scripts ───────────────────────────────────────────────
mkdir -p $BASE/python-devops-scripts
cat > $BASE/python-devops-scripts/Dockerfile << 'DOCKERFILE'
FROM python:3.11-slim
RUN apt-get update && apt-get install -y bash nano curl \
    && pip install requests psutil \
    && rm -rf /var/lib/apt/lists/*
RUN curl -fsSL https://github.com/tsl0922/ttyd/releases/download/1.7.4/ttyd.x86_64 \
    -o /usr/local/bin/ttyd && chmod +x /usr/local/bin/ttyd
RUN useradd -m -u 1000 -s /bin/bash labuser
COPY exercises/ /home/labuser/exercises/
RUN chown -R labuser:labuser /home/labuser
USER labuser
WORKDIR /home/labuser
EXPOSE 7681
ENTRYPOINT ["ttyd","-p","7681","-W","bash"]
DOCKERFILE

mkdir -p $BASE/python-devops-scripts/exercises
cat > $BASE/python-devops-scripts/exercises/monitor.py << 'PY'
"""
Build a system monitor that:
1. Uses psutil to get CPU and memory usage
2. Polls every 5 seconds
3. Writes metrics to a log file
4. Alerts (print WARNING) if CPU > 80% or memory > 90%
"""
import psutil, time, datetime

def get_metrics():
    return {
        "cpu_percent": psutil.cpu_percent(interval=1),
        "memory_percent": psutil.virtual_memory().percent,
        "timestamp": datetime.datetime.now().isoformat()
    }

def monitor(log_file="metrics.log", interval=5):
    # TODO: implement the monitoring loop
    pass

if __name__ == "__main__":
    monitor()
PY

echo ""
echo "✅ All lab image directories created under $BASE/"
echo ""
echo "Summary:"
echo "  Category 1 — Linux Fundamentals:      linux-shell-basics, linux-permissions, linux-processes, linux-text-processing"
echo "  Category 2 — Networking:               networking-tools, networking-http, networking-ssh"
echo "  Category 3 — Docker:                   docker-basics, docker-build, docker-compose-lab, docker-networking-lab"
echo "  Category 4 — Kubernetes:               k8s-kubectl-basics, k8s-deployments, k8s-services, k8s-configmaps-secrets"
echo "  Category 5 — Databases:                db-postgres-basics, db-redis-basics, db-mysql-basics, db-mongodb-basics"
echo "  Category 6 — CI/CD:                    cicd-git-workflows, cicd-github-actions, cicd-docker-pipeline, cicd-jenkins-basics"
echo "  Category 7 — IaC:                      iac-terraform-basics, iac-terraform-modules, iac-ansible-basics, iac-localstack-aws"
echo "  Category 8 — Observability:            obs-prometheus-basics, obs-log-analysis, obs-healthchecks"
echo "  Category 9 — Security:                 security-tls-basics, security-linux-hardening, security-secrets-vault, security-container-scanning"
echo "  Category 10 — Python for DevOps:       python-automation, python-cli-tools, python-yaml-json, python-devops-scripts"
echo ""
echo "Next: run bash create_lab_images.sh from your repo root, then run generate_seed.sql to insert all labs into the DB"
