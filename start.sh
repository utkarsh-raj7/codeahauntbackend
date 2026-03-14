#!/bin/bash
# ═══════════════════════════════════════════════════════
# CloudLab — One-Command Startup
# Usage: bash start.sh
# Stop:  Press Ctrl+C (kills all 3 processes)
# ═══════════════════════════════════════════════════════

set -e
cd "$(dirname "$0")"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'

echo -e "${CYAN}╔══════════════════════════════════════╗${NC}"
echo -e "${CYAN}║       ☁  CloudLab Startup            ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════╝${NC}"
echo ""

# ─── 1. Find Docker socket ───
if [ -S "$HOME/.colima/default/docker.sock" ]; then
    export DOCKER_SOCKET="$HOME/.colima/default/docker.sock"
    echo -e "${GREEN}✅ Docker (Colima):${NC} $DOCKER_SOCKET"
elif [ -S "/var/run/docker.sock" ]; then
    export DOCKER_SOCKET="/var/run/docker.sock"
    echo -e "${GREEN}✅ Docker:${NC} $DOCKER_SOCKET"
else
    echo -e "${RED}❌ Docker not found!${NC}"
    echo "   Start Colima: colima start --cpu 4 --memory 8"
    echo "   Or start Docker Desktop"
    exit 1
fi

# ─── 2. Check Docker is running ───
if ! DOCKER_HOST="unix://$DOCKER_SOCKET" docker info > /dev/null 2>&1; then
    echo -e "${RED}❌ Docker daemon not responding!${NC}"
    echo "   Try: colima start"
    exit 1
fi

# ─── 3. Check PostgreSQL ───
if ! psql postgresql://labuser:devpassword@localhost:5432/labdb -c "SELECT 1" > /dev/null 2>&1; then
    echo -e "${RED}❌ PostgreSQL not running or labdb not found!${NC}"
    echo "   Option A: docker compose -f docker/docker-compose.dev.yml up -d postgres"
    echo "   Option B: brew services start postgresql@16"
    echo "   Then: psql -U postgres -c \"CREATE USER labuser WITH PASSWORD 'devpassword'; CREATE DATABASE labdb OWNER labuser;\""
    exit 1
fi
echo -e "${GREEN}✅ PostgreSQL:${NC} labdb accessible"

# ─── 4. Check Redis ───
if ! redis-cli ping > /dev/null 2>&1; then
    echo -e "${RED}❌ Redis not running!${NC}"
    echo "   Option A: docker compose -f docker/docker-compose.dev.yml up -d redis"
    echo "   Option B: brew services start redis"
    exit 1
fi
echo -e "${GREEN}✅ Redis:${NC} connected"

# ─── 5. Create Docker network ───
DOCKER_HOST="unix://$DOCKER_SOCKET" docker network create lab-network 2>/dev/null && \
    echo -e "${GREEN}✅ Network:${NC} lab-network created" || \
    echo -e "${GREEN}✅ Network:${NC} lab-network exists"

# ─── 6. Check if node_modules exist ───
if [ ! -d "node_modules" ]; then
    echo -e "${YELLOW}📦 Installing dependencies...${NC}"
    npm install
fi

# ─── 7. Check if DB has users (seed if empty) ───
USER_COUNT=$(psql postgresql://labuser:devpassword@localhost:5432/labdb -t -c "SELECT count(*) FROM users;" 2>/dev/null | tr -d ' ')
if [ "$USER_COUNT" = "0" ] || [ -z "$USER_COUNT" ]; then
    echo -e "${YELLOW}🌱 Seeding database...${NC}"
    npx tsx src/db/seed.ts 2>/dev/null
    npx tsx src/db/seed-labs.ts 2>/dev/null
    echo -e "${GREEN}✅ Database seeded${NC}"
else
    echo -e "${GREEN}✅ Database:${NC} ${USER_COUNT} user(s), ready"
fi

# ─── 8. Start everything ───
echo ""
echo -e "${CYAN}Starting services...${NC}"
echo -e "  ${GREEN}API Server${NC}     → http://localhost:3001"
echo -e "  ${GREEN}Worker${NC}         → BullMQ job processor"
echo -e "  ${GREEN}Frontend${NC}       → http://localhost:5500/lab-test.html"
echo ""
echo -e "${YELLOW}Press Ctrl+C to stop everything${NC}"
echo ""

# Trap Ctrl+C to kill all background processes
trap 'echo -e "\n${RED}Shutting down...${NC}"; kill 0; exit 0' INT TERM

# Start API server
PORT=3001 DOCKER_SOCKET="$DOCKER_SOCKET" npx tsx src/server.ts &
API_PID=$!

# Start worker
sleep 2
DOCKER_SOCKET="$DOCKER_SOCKET" npx tsx src/jobs/index.ts &
WORKER_PID=$!

# Start frontend
sleep 1
npx serve -l 5500 public &
FRONTEND_PID=$!

echo ""
echo -e "${GREEN}═══════════════════════════════════════${NC}"
echo -e "${GREEN}  All services running!${NC}"
echo -e "${GREEN}  Open: http://localhost:5500/lab-test.html${NC}"
echo -e "${GREEN}═══════════════════════════════════════${NC}"
echo ""

# Wait for any process to exit
wait
