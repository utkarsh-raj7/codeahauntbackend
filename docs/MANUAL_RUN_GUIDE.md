# CloudLab — Manual Run Guide

## Prerequisites

| Tool | Version | Check |
|------|---------|-------|
| Node.js | 18+ | `node -v` |
| Docker | 24+ | `docker -v` |
| Colima (macOS) | latest | `colima status` |
| PostgreSQL | 16 | `psql --version` |
| Redis | 7 | `redis-cli ping` |

---

## 1. Infrastructure Setup

### Start Docker (macOS with Colima)
```bash
colima start --cpu 4 --memory 8
```

### Start PostgreSQL & Redis
```bash
# Option A: Use docker-compose (easiest)
docker compose -f docker/docker-compose.dev.yml up -d postgres redis

# Option B: Standalone
brew services start postgresql@16
brew services start redis
```

### Create Database
```bash
psql -U postgres -c "CREATE DATABASE labdb OWNER labuser;"
# Or if user doesn't exist:
psql -U postgres -c "CREATE USER labuser WITH PASSWORD 'devpassword'; CREATE DATABASE labdb OWNER labuser;"
```

### Create Docker Network
```bash
docker network create lab-network 2>/dev/null || true
```

---

## 2. Project Setup

```bash
cd "lab backend"

# Install dependencies
npm install

# Copy environment file
cp .env.example .env.dev

# Edit .env.dev with these values:
cat > .env.dev << 'EOF'
PORT=3001
NODE_ENV=development
DATABASE_URL=postgresql://labuser:devpassword@localhost:5432/labdb
REDIS_URL=redis://localhost:6379
JWT_SECRET=dev-secret-min-32-chars-long-here
DOCKER_SOCKET=/Users/$USER/.colima/default/docker.sock
CONTAINER_NETWORK=lab-network
MAX_ACTIVE_SESSIONS_PER_USER=100
MAX_TOTAL_ACTIVE_CONTAINERS=500
DEFAULT_SESSION_TTL=3600
KEEP_RECENT_SESSIONS=3
EOF
```

### Run Migrations & Seed
```bash
# Apply database schema
npx drizzle-kit push

# Seed the user + lab catalog
npx tsx src/db/seed.ts
npx tsx src/db/seed-labs.ts
```

---

## 3. Build Lab Docker Images

### Build All Images (one-time)
```bash
for dir in docker/lab-images/*/; do
    name=$(basename "$dir")
    echo "Building lab-${name}:latest..."
    docker build -q -t "lab-${name}:latest" "$dir"
done
```

### Build a Single Image
```bash
docker build -t lab-linux-shell-basics:latest docker/lab-images/linux-shell-basics/
```

### Known Working Images (tested on ARM64)
linux-shell-basics, linux-permissions, linux-processes, linux-text-processing,
networking-tools, networking-http, networking-ssh, docker-basics, docker-build,
docker-compose-lab, k8s-kubectl-basics, k8s-deployments, k8s-services,
k8s-configmaps-secrets, db-postgres-basics, db-redis-basics, db-mysql-basics,
db-mongodb-basics, cicd-git-workflows, cicd-github-actions, cicd-jenkins-basics,
iac-terraform-basics, iac-terraform-modules, iac-localstack-aws,
obs-prometheus-basics, obs-log-analysis, obs-healthchecks,
security-tls-basics, security-linux-hardening, security-secrets-vault,
python-automation, python-devops-scripts

---

## 4. Start the Application

You need **3 terminal windows**:

### Terminal 1 — API Server
```bash
PORT=3001 DOCKER_SOCKET=~/.colima/default/docker.sock npm run dev
```
> API runs at http://localhost:3001

### Terminal 2 — Background Worker
```bash
DOCKER_SOCKET=~/.colima/default/docker.sock npx tsx src/jobs/index.ts
```
> Processes provision/cleanup jobs from the BullMQ queue

### Terminal 3 — Frontend (optional)
```bash
npx serve -l 5500 public
```
> Frontend at http://localhost:5500/lab-test.html

---

## 5. Using the Web App

1. Open **http://localhost:5500/lab-test.html**
2. Browse labs by category (Linux, Docker, K8s, etc.)
3. Click a lab card → click **▶ Launch**
4. Wait ~15-25 seconds for provisioning
5. Terminal appears in the right panel — start working!

---

## 6. Using the API Directly

```bash
# Login
TOKEN=$(curl -s -X POST http://localhost:3001/api/v1/auth/login \
  -H 'Content-Type: application/json' \
  -d '{"email":"seed-user@example.com","password":"password123"}' \
  | python3 -c "import sys,json; print(json.load(sys.stdin)['access_token'])")

# List all labs
curl -s http://localhost:3001/api/v1/catalog/labs?limit=50 | python3 -m json.tool

# Provision a lab
curl -s -X POST http://localhost:3001/api/v1/labs/linux-shell-basics/provision \
  -H "Authorization: Bearer $TOKEN" -H 'Content-Type: application/json' -d '{}'

# Check status (replace SESSION_ID)
curl -s http://localhost:3001/api/v1/labs/<SESSION_ID>/status \
  -H "Authorization: Bearer $TOKEN"

# Heartbeat (extend TTL)
curl -s -X POST http://localhost:3001/api/v1/labs/<SESSION_ID>/heartbeat \
  -H "Authorization: Bearer $TOKEN"

# Destroy session
curl -s -X DELETE http://localhost:3001/api/v1/labs/<SESSION_ID> \
  -H "Authorization: Bearer $TOKEN"
```

---

## 7. Auto-Cleanup Behavior

The system **automatically prunes old sessions** to save disk/memory:

- **Keeps**: The 3 most recent sessions per user (configurable via `KEEP_RECENT_SESSIONS`)
- **Prunes**: Older containers are stopped, removed, and marked `destroyed`
- **When**: Runs automatically before each new provision
- **Blocking**: No — new provisions are never blocked by cleanup

Example log output:
```
[auto-prune] User a1b2c3d4: pruning 2 old session(s), keeping 3
[auto-prune] Destroyed session e5f6g7h8 (lab: linux-shell-basics)
[auto-prune] Destroyed session i9j0k1l2 (lab: networking-tools)
```

---

## 8. Environment Variables Reference

| Variable | Default | Description |
|----------|---------|-------------|
| `PORT` | 3001 | API server port |
| `DOCKER_SOCKET` | `/var/run/docker.sock` | Docker socket path |
| `MAX_ACTIVE_SESSIONS_PER_USER` | 100 | Max concurrent sessions per user |
| `MAX_TOTAL_ACTIVE_CONTAINERS` | 500 | Max total containers on system |
| `DEFAULT_SESSION_TTL` | 3600 | Session TTL in seconds (1 hour) |
| `KEEP_RECENT_SESSIONS` | 3 | Sessions to keep, older ones auto-pruned |
| `CONTAINER_CPU_LIMIT` | 0.5 | CPU cores per container |
| `CONTAINER_MEMORY_LIMIT` | 536870912 | Memory limit per container (512 MB) |

---

## 9. Troubleshooting

| Problem | Fix |
|---------|-----|
| `QUOTA_EXCEEDED` | Old sessions stuck. Run: `psql $DATABASE_URL -c "UPDATE sessions SET status='destroyed' WHERE status IN ('ready','provisioning','error');"` |
| Lab stuck at "provisioning" | Worker not running. Start Terminal 2 |
| "Press enter to reconnect" | ttyd binary missing in image. Rebuild: `docker build -t lab-<name>:latest docker/lab-images/<name>/` |
| `ECONNREFUSED` on API | Server not running. Start Terminal 1 |
| Port conflict | Kill existing: `lsof -ti:3001 \| xargs kill` |
| Docker socket not found | Check colima is running: `colima status` |

---

## 10. Quick One-Liner Test

```bash
# Full end-to-end: login → provision → poll → open terminal
TOKEN=$(curl -s -X POST http://localhost:3001/api/v1/auth/login -H 'Content-Type: application/json' -d '{"email":"seed-user@example.com","password":"password123"}' | python3 -c "import sys,json; print(json.load(sys.stdin)['access_token'])") && \
SID=$(curl -s -X POST http://localhost:3001/api/v1/labs/linux-shell-basics/provision -H "Authorization: Bearer $TOKEN" -H 'Content-Type: application/json' -d '{}' | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('session_id', d.get('id','ERROR')))") && \
echo "Session: $SID — waiting 20s..." && sleep 20 && \
curl -s http://localhost:3001/api/v1/labs/$SID/status -H "Authorization: Bearer $TOKEN" | python3 -m json.tool
```
