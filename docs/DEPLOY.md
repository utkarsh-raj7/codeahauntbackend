# CloudLab — Deployment Guide

## Requirements

- A VPS with **2+ CPU cores**, **4GB+ RAM**, **40GB+ disk**
- Docker 24+ and Docker Compose v2 installed
- A domain name (optional but recommended)

> **⚠ Why not Render/Railway?** This app provisions Docker containers for each lab session, requiring Docker socket access. PaaS platforms don't expose the Docker daemon. A VPS with Docker is required.

## Recommended Providers

| Provider | Plan | Cost |
|----------|------|------|
| DigitalOcean Droplet | 4GB RAM, 2 vCPU | $24/mo |
| Hetzner Cloud | CX21 | €5.50/mo |
| AWS EC2 | t3.medium | ~$30/mo |

---

## Quick Deploy (5 minutes)

```bash
# 1. SSH into your VPS
ssh root@your-server-ip

# 2. Install Docker (if not installed)
curl -fsSL https://get.docker.com | sh
systemctl enable docker

# 3. Clone and deploy
git clone https://github.com/utkarsh-raj7/codeahauntbackend.git /opt/cloudlab
cd /opt/cloudlab
chmod +x deploy.sh
./deploy.sh
```

The deploy script will:
1. ✅ Check Docker is installed
2. ✅ Generate secure JWT + DB passwords
3. ✅ Build the API (multi-stage, ~150MB image)
4. ✅ Start Postgres, Redis, API, Worker, Nginx, Traefik
5. ✅ Run database migrations + seed labs
6. ✅ Build all 40 lab Docker images
7. ✅ Print access URLs

---

## Manual Setup

### 1. Configure Environment
```bash
cd /opt/cloudlab
cp .env.production.example .env.production
nano .env.production
```

Key settings to change:
```env
BASE_DOMAIN=labs.yourdomain.com    # Your domain
POSTGRES_PASSWORD=<generated>       # Strong password
JWT_SECRET=<generated>              # 64-char hex
FIREBASE_PROJECT_ID=your-id         # Firebase creds
MAX_ACTIVE_SESSIONS_PER_USER=3      # Per-user limit
MAX_TOTAL_ACTIVE_CONTAINERS=50      # Server capacity
```

### 2. Start Services
```bash
docker compose -f docker-compose.prod.yml up -d
```

### 3. Run Migrations
```bash
docker compose -f docker-compose.prod.yml exec api npx drizzle-kit push
docker compose -f docker-compose.prod.yml exec api node dist/db/seed.js
docker compose -f docker-compose.prod.yml exec api node dist/db/seed-labs.js
```

### 4. Build Lab Images
```bash
for dir in docker/lab-images/*/; do
    name=$(basename "$dir")
    docker build -q -t "lab-${name}:latest" "$dir"
done
```

---

## SSL with Let's Encrypt

```bash
# Install certbot
apt install certbot -y

# Get certificate
certbot certonly --standalone -d yourdomain.com

# Copy certs for Nginx
cp /etc/letsencrypt/live/yourdomain.com/fullchain.pem nginx/certs/
cp /etc/letsencrypt/live/yourdomain.com/privkey.pem nginx/certs/

# Restart Nginx
docker compose -f docker-compose.prod.yml restart nginx
```

---

## Operations

```bash
# View logs
docker compose -f docker-compose.prod.yml logs -f api worker

# Restart everything
docker compose -f docker-compose.prod.yml restart

# Stop everything
docker compose -f docker-compose.prod.yml down

# Update code
git pull origin main
docker compose -f docker-compose.prod.yml up -d --build

# Check health
curl http://localhost:3000/health
curl http://localhost:3000/ready
```

---

## Architecture

```
                  ┌─────────────────────────────────┐
                  │           Nginx (:80/:443)       │
                  │   Frontend static files           │
                  │   /api/* → API server              │
                  └──────┬──────────────────────────┘
                         │
              ┌──────────┼──────────┐
              │          │          │
        ┌─────▼─────┐   │   ┌──────▼──────┐
        │ API (:3000)│   │   │   Worker     │
        │ Fastify    │   │   │ BullMQ jobs  │
        └─────┬──────┘   │   └──────┬───────┘
              │          │          │
        ┌─────▼──────────▼──────────▼───────┐
        │    Docker Socket (/var/run/...)    │
        │                                    │
        │   ┌────────┐ ┌────────┐ ┌──────┐  │
        │   │Lab Pod1│ │Lab Pod2│ │Lab..N│  │
        │   └────────┘ └────────┘ └──────┘  │
        └───────────────────────────────────┘
              │          │
        ┌─────▼───┐  ┌──▼────┐
        │Postgres │  │ Redis │
        └─────────┘  └───────┘
```

## Resource Planning

| Lab Containers | RAM Needed | CPU Needed |
|----------------|-----------|------------|
| 5 concurrent   | 4 GB      | 2 cores    |
| 10 concurrent  | 8 GB      | 4 cores    |
| 25 concurrent  | 16 GB     | 8 cores    |
| 50 concurrent  | 32 GB     | 16 cores   |

Each lab container uses ~512MB RAM and 0.5 CPU by default (configurable via `CONTAINER_MEMORY_LIMIT` and `CONTAINER_CPU_LIMIT`).
