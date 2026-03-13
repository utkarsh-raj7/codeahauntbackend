# CodeAhaunt Lab Backend

Interactive lab environment backend — provisions sandboxed Docker containers for hands-on coding labs with real-time WebSocket communication, session management, and automated cleanup.

## Architecture

```
┌──────────────────────────────────────────────────────────────┐
│  Fastify API Server (src/app.ts)                             │
│  ├── /api/v1/auth    → login, refresh, logout                │
│  ├── /api/v1/catalog → public lab listing (Redis cached)     │
│  ├── /api/v1/labs    → provision, status, heartbeat, destroy │
│  ├── /api/v1/schedule→ schedule/cancel future labs            │
│  ├── /api/v1/admin   → admin-only metrics (role guarded)     │
│  └── /ws/v1/labs/:id → WebSocket events + heartbeat          │
├──────────────────────────────────────────────────────────────┤
│  Services Layer                                              │
│  ├── auth.service        → JWT + bcrypt + replay detection   │
│  ├── orchestrator        → provision/destroy lifecycle       │
│  ├── container.service   → Docker API (create/start/stop)    │
│  ├── session.service     → heartbeat + TTL extension         │
│  ├── validation.service  → exec step commands in containers  │
│  ├── scheduler.service   → future lab scheduling             │
│  └── notification.service→ WS events + email via BullMQ     │
├──────────────────────────────────────────────────────────────┤
│  Infrastructure                                              │
│  ├── PostgreSQL 16   → users, sessions, labs                 │
│  ├── Redis 7         → session TTL, catalog cache, pub/sub   │
│  ├── BullMQ          → provision, cleanup, monitor workers   │
│  ├── Traefik v3      → dynamic routing to lab containers     │
│  └── Docker          → sandboxed lab containers              │
└──────────────────────────────────────────────────────────────┘
```

## Quick Start

```bash
# 1. Clone
git clone https://github.com/utkarsh-raj7/codeahauntbackend.git
cd codeahauntbackend

# 2. Install
npm install

# 3. Configure environment
cp .env.example .env.dev
# Edit .env.dev — fill in real values (see "Files to Configure" below)

# 4. Start infrastructure
colima start                    # macOS only — starts Docker VM
docker-compose -f docker/docker-compose.dev.yml up -d

# 5. Run migrations and seed
npm run db:migrate
npm run db:seed

# 6. Start dev server
npm run dev                     # API on port 3000
npm run dev:worker              # BullMQ workers (separate terminal)
```

## Files That Need Configuration

These files are **NOT committed** to the repo and must be created/configured manually:

| File | Purpose | How to Create |
|------|---------|---------------|
| `.env.dev` | Local dev environment variables | `cp .env.example .env.dev` then fill in real values |
| `docker/.env.dev` | Docker container env variables | Copy `.env.dev` but change `localhost` → Docker service names (`postgres`, `redis`) |

### Secrets that MUST be changed from defaults

| Variable | Where to Get It |
|----------|----------------|
| `JWT_SECRET` | Generate: `openssl rand -hex 32` |
| `JWT_EMBED_SECRET` | Generate: `openssl rand -hex 32` |
| `FIREBASE_PROJECT_ID` | Firebase Console → Project Settings |
| `FIREBASE_ADMIN_CLIENT_EMAIL` | Firebase Console → Service Accounts |
| `FIREBASE_ADMIN_PRIVATE_KEY` | Firebase Console → Service Accounts → Generate New Private Key |
| `SMTP_HOST/USER/PASS` | Your email provider (SendGrid, Mailgun, etc.) |

### GitHub Actions Secrets (for CI/CD)

Add these in GitHub → Settings → Secrets → Actions:

- `FIREBASE_PROJECT_ID`
- `FIREBASE_ADMIN_CLIENT_EMAIL`
- `FIREBASE_ADMIN_PRIVATE_KEY`
- `JWT_SECRET`
- `JWT_EMBED_SECRET`

## npm Scripts

| Script | Description |
|--------|-------------|
| `npm run dev` | Start API server with hot-reload |
| `npm run dev:worker` | Start BullMQ workers with hot-reload |
| `npm run build` | Compile TypeScript to `dist/` |
| `npm run lint` | ESLint check on `src/` |
| `npm run test` | Run all test suites |
| `npm run test:ts01` | Auth tests only (5 tests) |
| `npm run test:ts02` | Provision tests only (8 tests) |
| `npm run db:migrate` | Run Drizzle migrations |
| `npm run db:seed` | Seed database with test data |

## API Endpoints

### Auth (`/api/v1/auth`) — Rate limited

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| POST | `/login` | ✗ | Login with email/password (5 req/IP/60s) |
| POST | `/refresh` | ✗ | Refresh access token |
| POST | `/logout` | ✓ | Revoke refresh token family |

### Catalog (`/api/v1/catalog`) — Public

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | `/labs` | ✗ | List active labs (Redis cached, 5min TTL) |

### Labs (`/api/v1/labs`) — Authenticated

| Method | Path | Auth | Guard | Description |
|--------|------|------|-------|-------------|
| GET | `/sessions` | ✓ | — | List user's sessions |
| POST | `/:labId/provision` | ✓ | — | Provision a new lab container |
| GET | `/:sessionId/status` | ✓ | ownerGuard | Get session status + terminal URL |
| POST | `/:sessionId/heartbeat` | ✓ | ownerGuard | Reset session TTL |
| DELETE | `/:sessionId` | ✓ | ownerGuard | Destroy session |
| POST | `/:sessionId/destroy` | ✓ | ownerGuard | Destroy (sendBeacon compat) |

### Schedule (`/api/v1/schedule`) — Authenticated

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| POST | `/` | ✓ | Schedule a future lab |
| GET | `/` | ✓ | List scheduled labs |
| DELETE | `/:scheduleId` | ✓ | Cancel scheduled lab |

### Admin (`/api/v1/admin`) — Admin Only

| Method | Path | Auth | Guard | Description |
|--------|------|------|-------|-------------|
| GET | `/metrics` | ✓ | adminOnly | System metrics |

### WebSocket (`/ws/v1/labs`)

```
ws://host/ws/v1/labs/:sessionId/events
Subprotocol: "Bearer, <access_token>"
```

**Events received:**
- `connected` — initial connection with `time_remaining_seconds`
- `heartbeat_ack` — response to heartbeat with updated TTL
- `time_warning` — sent when TTL ≤ 300s
- `session_expired` — session TTL reached 0, socket closes

**Messages to send:**
- `{"type": "heartbeat"}` — resets session TTL

## Project Structure

```
src/
├── app.ts                    # Fastify app setup, plugin registration
├── server.ts                 # Server entry point
├── config/
│   ├── database.ts           # Drizzle + PostgreSQL connection
│   ├── firebase-admin.ts     # Firebase Admin SDK init
│   └── redis.ts              # Redis client + keyspace events
├── db/
│   ├── schema/               # Drizzle table schemas (users, sessions, labs)
│   ├── migrations/           # SQL migration files
│   └── seed.ts               # Test data seeder
├── middleware/
│   ├── authenticate.ts       # Dual-path auth (Firebase + internal JWT)
│   ├── ownerGuard.ts         # Session ownership verification
│   └── errorHandler.ts       # Centralized error formatting
├── routes/
│   ├── auth.routes.ts        # Login, refresh, logout
│   ├── catalog.routes.ts     # Public lab catalog (cached)
│   ├── labs.routes.ts        # Lab lifecycle (provision/destroy)
│   ├── schedule.routes.ts    # Lab scheduling
│   └── admin.routes.ts       # Admin-only endpoints
├── services/
│   ├── auth.service.ts       # Password hashing, JWT issuance, replay detection
│   ├── orchestrator.service.ts # Provision/destroy orchestration
│   ├── container.service.ts  # Docker API wrapper
│   ├── session.service.ts    # Heartbeat, TTL extension
│   ├── validation.service.ts # In-container step validation
│   ├── scheduler.service.ts  # Future lab scheduling
│   ├── notification.service.ts # WS + email notifications
│   └── resource.service.ts   # Container resource monitoring
├── jobs/
│   ├── index.ts              # Worker entry point
│   ├── provision.job.ts      # Container creation worker
│   ├── cleanup.job.ts        # Expired session cleanup
│   └── monitor.job.ts        # Health monitoring
├── websocket/
│   └── gateway.ts            # WebSocket handler (heartbeat, time warnings)
└── utils/
    └── publishEvent.ts       # Redis pub/sub event publisher
```

## Security

- **Dual-path authentication**: Firebase ID tokens + internal JWT
- **Embed tokens**: Scoped tokens for terminal iframe access, rejected on REST endpoints
- **Owner guard**: Every `:sessionId` route verifies `session.userId === req.user.sub`
- **Container isolation**: `no-new-privileges`, dedicated Docker network, resource limits
- **Rate limiting**: 5 req/IP/60s on login, global limits on all endpoints
- **Replay attack detection**: Refresh token families with Redis-backed revocation

## Testing

```bash
npm run test              # All tests (13 total)
npm run test:ts01         # Auth suite: password hashing, JWT, replay detection
npm run test:ts02         # Provision suite: lifecycle, quota, idempotency, ownership
```
