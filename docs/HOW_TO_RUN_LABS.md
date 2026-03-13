# How to Run Labs

## Prerequisites

Make sure these are running:

```bash
# 1. Start Docker (Colima on macOS)
colima start

# 2. Start Postgres + Redis + Traefik
docker compose -f docker/docker-compose.dev.yml up -d

# 3. Start the API server
PORT=3001 DOCKER_SOCKET=/Users/utkarshraj/.colima/default/docker.sock npm run dev

# 4. Start the worker (new terminal)
DOCKER_SOCKET=/Users/utkarshraj/.colima/default/docker.sock npx tsx src/jobs/index.ts
```

---

## Step 1 — Build a Lab Image

Each lab has a Dockerfile under `docker/lab-images/<lab-name>/`. Build it:

```bash
# Example: Linux Shell Basics
docker build -t lab-linux-shell-basics:latest docker/lab-images/linux-shell-basics/

# Example: PostgreSQL lab
docker build -t lab-db-postgres-basics:latest docker/lab-images/db-postgres-basics/
```

> **Image naming convention:** `lab-<lab-id>:latest`
> The `dockerImage` field in the DB must match this tag exactly.

---

## Step 2 — Seed the Lab into the Database

If you haven't already:

```bash
npx tsx src/db/seed-labs.ts
```

This inserts all 38 labs into PostgreSQL. It uses `onConflictDoNothing`, so it's safe to run multiple times.

---

## Step 3 — Login and Get a Token

```bash
TOKEN=$(curl -s -X POST http://localhost:3001/api/v1/auth/login \
  -H 'Content-Type: application/json' \
  -d '{"email":"seed-user@example.com","password":"password123"}' \
  | python3 -c "import sys,json; print(json.load(sys.stdin)['access_token'])")

echo $TOKEN   # verify you got a JWT
```

---

## Step 4 — Provision a Lab

```bash
curl -s -X POST http://localhost:3001/api/v1/labs/<lab-id>/provision \
  -H "Authorization: Bearer $TOKEN" \
  -H 'Content-Type: application/json' -d '{}' | python3 -m json.tool
```

Replace `<lab-id>` with any seeded lab ID. Available lab IDs:

| Category | Lab IDs |
|----------|---------|
| Linux | `linux-shell-basics`, `linux-permissions`, `linux-processes`, `linux-text-processing` |
| Networking | `networking-tools`, `networking-http`, `networking-ssh` |
| Docker | `docker-basics`, `docker-build`, `docker-compose-lab`, `docker-networking-lab` |
| Kubernetes | `k8s-kubectl-basics`, `k8s-deployments`, `k8s-services`, `k8s-configmaps-secrets` |
| Databases | `db-postgres-basics`, `db-redis-basics`, `db-mysql-basics`, `db-mongodb-basics` |
| CI/CD | `cicd-git-workflows`, `cicd-github-actions`, `cicd-docker-pipeline`, `cicd-jenkins-basics` |
| IaC | `iac-terraform-basics`, `iac-terraform-modules`, `iac-ansible-basics`, `iac-localstack-aws` |
| Observability | `obs-prometheus-basics`, `obs-log-analysis`, `obs-healthchecks` |
| Security | `security-tls-basics`, `security-linux-hardening`, `security-secrets-vault`, `security-container-scanning` |
| Python | `python-automation`, `python-cli-tools`, `python-yaml-json`, `python-devops-scripts` |

You'll get back:
```json
{
  "session_id": "abc123...",
  "status": "provisioning",
  "expiresAt": "..."
}
```

---

## Step 5 — Wait for Ready + Get Terminal URL

Poll the status (~15-30 seconds):

```bash
curl -s http://localhost:3001/api/v1/labs/<session_id>/status \
  -H "Authorization: Bearer $TOKEN" | python3 -m json.tool
```

When ready:
```json
{
  "status": "ready",
  "terminal_url": "http://localhost:32771"
}
```

**Open `terminal_url` in your browser** → you get a bash shell inside the lab container.

---

## Step 6 — Use the Lab

The terminal is a real Linux environment. Each lab has pre-loaded exercises:
- Sample files in `~/workspace/` or `~/exercises/`
- Services running (databases, HTTP servers, etc.)
- Instructions printed on first connect

---

## Step 7 — Heartbeat & Destroy

```bash
# Keep session alive (send every 5 min)
curl -s -X POST http://localhost:3001/api/v1/labs/<session_id>/heartbeat \
  -H "Authorization: Bearer $TOKEN"

# Destroy when done
curl -s -X DELETE http://localhost:3001/api/v1/labs/<session_id> \
  -H "Authorization: Bearer $TOKEN"
```

---

## Quick One-Liner (Full Flow)

```bash
# Build + provision + open terminal
LAB=linux-shell-basics && \
docker build -t lab-$LAB:latest docker/lab-images/$LAB/ && \
TOKEN=$(curl -s -X POST http://localhost:3001/api/v1/auth/login \
  -H 'Content-Type: application/json' \
  -d '{"email":"seed-user@example.com","password":"password123"}' \
  | python3 -c "import sys,json; print(json.load(sys.stdin)['access_token'])") && \
SID=$(curl -s -X POST http://localhost:3001/api/v1/labs/$LAB/provision \
  -H "Authorization: Bearer $TOKEN" -H 'Content-Type: application/json' -d '{}' \
  | python3 -c "import sys,json; print(json.load(sys.stdin)['session_id'])") && \
echo "Session: $SID — waiting..." && sleep 25 && \
curl -s http://localhost:3001/api/v1/labs/$SID/status \
  -H "Authorization: Bearer $TOKEN" | python3 -m json.tool
```

Then open the `terminal_url` from the output in your browser.

---

## Troubleshooting

| Problem | Fix |
|---------|-----|
| `status` stays `provisioning` | Check the worker is running (`npx tsx src/jobs/index.ts`) |
| "Press Enter to Reconnect" loop | Rebuild image — check arch: `docker exec <container> uname -m` must match ttyd binary |
| `terminal_url` doesn't load | Check container is running: `docker ps \| grep lab-` |
| Login fails / hangs | Verify Postgres is up: `docker ps \| grep postgres` |
| `dockerImage not found` | Build the image first: `docker build -t lab-<id>:latest docker/lab-images/<id>/` |
