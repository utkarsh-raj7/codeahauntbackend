#!/usr/bin/env bash
set -euo pipefail

# ═══════════════════════════════════════════════
# CloudLab Deploy Script
# Run on a fresh VPS with Docker installed
# ═══════════════════════════════════════════════

REPO_URL="${REPO_URL:-https://github.com/utkarsh-raj7/codeahauntbackend.git}"
APP_DIR="${APP_DIR:-/opt/cloudlab}"
COMPOSE_FILE="docker-compose.prod.yml"

echo ""
echo "╔══════════════════════════════════════════╗"
echo "║    ☁  CloudLab Deploy                     ║"
echo "╚══════════════════════════════════════════╝"
echo ""

# ─── 1. Check prerequisites ───
command -v docker >/dev/null 2>&1 || { echo "❌ Docker not installed. Run: curl -fsSL https://get.docker.com | sh"; exit 1; }
command -v docker compose >/dev/null 2>&1 || command -v docker-compose >/dev/null 2>&1 || { echo "❌ Docker Compose not found"; exit 1; }
echo "✅ Docker $(docker --version | cut -d' ' -f3)"

# ─── 2. Clone or pull repo ───
if [ -d "$APP_DIR/.git" ]; then
    echo "📥 Updating existing repo..."
    cd "$APP_DIR"
    git pull origin main
else
    echo "📥 Cloning repo..."
    git clone "$REPO_URL" "$APP_DIR"
    cd "$APP_DIR"
fi

# ─── 3. Create .env.production if missing ───
if [ ! -f ".env.production" ]; then
    echo "📝 Creating .env.production from template..."
    cp .env.production.example .env.production
    # Generate random JWT secret
    JWT_SECRET=$(openssl rand -hex 32)
    sed -i "s|CHANGE_ME_JWT_SECRET|$JWT_SECRET|g" .env.production
    POSTGRES_PASS=$(openssl rand -hex 16)
    sed -i "s|CHANGE_ME_DB_PASS|$POSTGRES_PASS|g" .env.production
    echo "⚠  Edit .env.production with your domain and Firebase credentials before going live"
fi

# ─── 4. Create Docker network ───
docker network create lab-network 2>/dev/null || true

# ─── 5. Build & start services ───
echo "🔨 Building production images..."
docker compose -f "$COMPOSE_FILE" build --no-cache

echo "🚀 Starting services..."
docker compose -f "$COMPOSE_FILE" up -d

# ─── 6. Wait for healthy API ───
echo "⏳ Waiting for API to be healthy..."
for i in $(seq 1 30); do
    if curl -sf http://localhost:3000/health >/dev/null 2>&1; then
        echo "✅ API healthy"
        break
    fi
    sleep 2
done

# ─── 7. Run migrations & seed ───
echo "🗄  Running database migrations..."
docker compose -f "$COMPOSE_FILE" exec api node -e "
const { execSync } = require('child_process');
try { execSync('npx drizzle-kit push', { stdio: 'inherit', cwd: '/app' }); } catch(e) { console.warn('Migration warning:', e.message); }
"

echo "🌱 Seeding database..."
docker compose -f "$COMPOSE_FILE" exec api node dist/db/seed.js 2>/dev/null || echo "  (seed may already exist)"
docker compose -f "$COMPOSE_FILE" exec api node dist/db/seed-labs.js 2>/dev/null || echo "  (labs may already exist)"

# ─── 8. Build lab images ───
echo "🐳 Building lab Docker images..."
for dir in docker/lab-images/*/; do
    name=$(basename "$dir")
    if docker image inspect "lab-${name}:latest" >/dev/null 2>&1; then
        echo "  ⏭  lab-${name} (cached)"
    else
        echo "  🔨 Building lab-${name}..."
        docker build -q -t "lab-${name}:latest" "$dir" || echo "  ⚠  Failed: $name"
    fi
done

# ─── 9. Summary ───
echo ""
echo "═══════════════════════════════════════════"
echo "✅ CloudLab deployed!"
echo ""
echo "  Frontend:  http://$(hostname -I 2>/dev/null | awk '{print $1}' || echo 'localhost')"
echo "  API:       http://$(hostname -I 2>/dev/null | awk '{print $1}' || echo 'localhost'):3000"
echo "  Traefik:   http://$(hostname -I 2>/dev/null | awk '{print $1}' || echo 'localhost'):8080"
echo ""
echo "  Logs:      docker compose -f $COMPOSE_FILE logs -f"
echo "  Stop:      docker compose -f $COMPOSE_FILE down"
echo "  Restart:   docker compose -f $COMPOSE_FILE restart"
echo "═══════════════════════════════════════════"
