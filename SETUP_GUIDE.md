# CloudLab Backend — Setup Guide for Frontend Integration

> **Audience**: Frontend developer cloning this repo to connect the Next.js frontend.  
> **Time to set up**: ~10 minutes.

---

## Prerequisites (Install Once)

| Tool | Install | Required? |
|------|---------|-----------|
| **Node.js 20+** | [nodejs.org](https://nodejs.org) | ✅ Yes |
| **PostgreSQL 16** | [postgresql.org](https://www.postgresql.org/download/) | ✅ Yes |
| **Redis** | **Windows**: [Memurai](https://www.memurai.com/) · **Mac**: `brew install redis` · **Docker**: `docker run -d -p 6379:6379 redis:alpine` | ✅ Yes |
| **Docker Engine** | Only for actual container provisioning | ❌ Not needed for UI dev |
| **SMTP credentials** | Gmail App Password / Resend / Brevo | ❌ Optional (emails queue silently) |

---

## Step-by-Step Setup

### 1. Clone & Install

```bash
git clone https://github.com/utkarsh-raj7/codeahauntbackend.git
cd codeahauntbackend
npm install
```

### 2. Create the Database

```sql
-- Connect to PostgreSQL
psql -U postgres

-- Run these 3 commands:
CREATE DATABASE labdb;
CREATE USER labuser WITH PASSWORD 'devpassword';
GRANT ALL PRIVILEGES ON DATABASE labdb TO labuser;
\q
```

### 3. Configure Environment

```bash
cp .env.example .env.dev
```

Open `.env.dev` and verify these values match your local setup:

```env
DATABASE_URL=postgresql://labuser:devpassword@localhost:5432/labdb
REDIS_URL=redis://localhost:6379
```

> **Firebase keys**: Get from Firebase Console → Project Settings → Service Accounts → Generate New Private Key. The private key must be on **ONE line** with `\n` for newlines.

### 4. Run Migrations & Seed

```bash
npx drizzle-kit migrate     # Creates tables
npx tsx src/db/seed.ts       # Seeds 2 labs + 1 test user
```

### 5. Start the Backend

```bash
npm run dev                  # API server on http://localhost:3000
```

> For frontend proxy compatibility, you may want to run on port 3001:
> ```bash
> PORT=3001 npm run dev
> ```

### 6. Verify It Works

```bash
curl http://localhost:3001/health        # → {"status":"ok"}
curl http://localhost:3001/api/v1/catalog/labs  # → [2 seeded labs]
```

---

## Frontend Proxy Setup

In your Next.js `next.config.ts`, proxy API calls to the backend:

```typescript
// next.config.ts
const nextConfig = {
  async rewrites() {
    return [
      {
        source: '/api/v1/:path*',
        destination: 'http://localhost:3001/api/v1/:path*',
      },
      {
        source: '/ws/:path*',
        destination: 'http://localhost:3001/ws/:path*',
      },
    ];
  },
};
```

Add to your frontend `.env`:
```env
LAB_API_URL=http://localhost:3001
```

---

## API Quick Reference

### Auth — No Token Needed

| Method | Endpoint | Body | Response |
|--------|----------|------|----------|
| POST | `/api/v1/auth/login` | `{ email, password }` | `{ access_token, refresh_token }` |
| POST | `/api/v1/auth/refresh` | `{ refresh_token }` | `{ access_token, refresh_token }` |
| POST | `/api/v1/auth/logout` | `{ refresh_token }` | `{ status: "logged_out" }` |

**Test credentials** (from seed): `seed-user@example.com` / `password123`

### Catalog — Public, No Token

| Method | Endpoint | Response |
|--------|----------|----------|
| GET | `/api/v1/catalog/labs` | `[{ id, title, description, difficulty, ... }]` |
| GET | `/api/v1/catalog/labs/:labId` | `{ id, title, steps, ... }` |

### Labs — Requires `Authorization: Bearer <token>`

| Method | Endpoint | Body | Response |
|--------|----------|------|----------|
| GET | `/api/v1/labs/sessions` | — | `[{ id, labId, status, ... }]` |
| POST | `/api/v1/labs/:labId/provision` | `{}` | `{ id, status: "provisioning" }` |
| GET | `/api/v1/labs/:sessionId/status` | — | `{ status, terminal_url }` |
| POST | `/api/v1/labs/:sessionId/heartbeat` | — | `{ time_remaining_seconds }` |
| POST | `/api/v1/labs/:sessionId/extend` | `{ extendBySeconds? }` | `{ status, expires_at, time_remaining_seconds }` |
| POST | `/api/v1/labs/:sessionId/validate/:stepId` | — | `{ stepId, passed, output, exitCode }` |
| GET | `/api/v1/labs/:sessionId/progress` | — | `{ steps: [{id, name, completed}], completedCount, totalCount }` |
| DELETE | `/api/v1/labs/:sessionId` | — | `{ status: "destroyed" }` |
| POST | `/api/v1/labs/:sessionId/destroy` | — | `{ status: "destroyed" }` (sendBeacon) |

### Schedule — Requires Token

| Method | Endpoint | Body | Response |
|--------|----------|------|----------|
| GET | `/api/v1/schedule/slots?labId=X&date=Y` | — | `[{ id, startTime, endTime, available }]` |
| POST | `/api/v1/schedule/book` | `{ labId, slotId, scheduledAt }` | `{ id, scheduledAt, status }` |
| GET | `/api/v1/schedule/my-bookings` | — | `[{ id, labId, scheduledAt, status }]` |
| DELETE | `/api/v1/schedule/:scheduleId` | — | `{ status: "cancelled" }` |

### WebSocket — Real-time Events

```javascript
const ws = new WebSocket(
  `ws://localhost:3001/ws/v1/labs/${sessionId}/events`,
  ['Bearer', accessToken]
);

ws.onmessage = (event) => {
  const data = JSON.parse(event.data);
  // data.type: 'connected' | 'heartbeat_ack' | 'time_warning' | 'session_expired'
};

// Send heartbeat every 30s
setInterval(() => ws.send(JSON.stringify({ type: 'heartbeat' })), 30000);
```

---

## Frontend ↔ Backend API Mapping

```
lab-api.ts function        →  Backend Route
─────────────────────────────────────────────
fetchLabCatalog()          →  GET  /api/v1/catalog/labs
fetchLabDefinition(id)     →  GET  /api/v1/catalog/labs/:id
provisionLab(labId)        →  POST /api/v1/labs/:labId/provision
getSessionStatus(id)       →  GET  /api/v1/labs/:id/status
sendHeartbeat(id)          →  POST /api/v1/labs/:id/heartbeat
extendSession(id)          →  POST /api/v1/labs/:id/extend
validateStep(sid, stepId)  →  POST /api/v1/labs/:id/validate/:stepId
getSessionProgress(id)     →  GET  /api/v1/labs/:id/progress
destroySession(id)         →  DELETE /api/v1/labs/:id
getUserSessions()          →  GET  /api/v1/labs/sessions
getAvailableSlots(id,date) →  GET  /api/v1/schedule/slots?labId=X&date=Y
bookSlot(...)              →  POST /api/v1/schedule/book
getMyBookings()            →  GET  /api/v1/schedule/my-bookings
cancelBooking(id)          →  DELETE /api/v1/schedule/:id
```

**All routes are implemented. Zero stubs remaining.**

---

## Running Both Servers

```bash
# Terminal 1 — Backend
cd codeahauntbackend
npm run dev                    # or: PORT=3001 npm run dev

# Terminal 2 — Frontend
cd VirtualML                   # or your frontend directory
npm run dev                    # Next.js on http://localhost:3000
```

**How auth works**: Frontend signs in with Firebase → gets Firebase ID token → sends it as `Authorization: Bearer <firebase_token>` → Backend verifies it via Firebase Admin SDK. For local testing without Firebase, use the `/auth/login` endpoint with seed credentials.

---

## What You DON'T Need for Frontend Dev

| Thing | Why You Can Skip It |
|-------|-------------------|
| Docker Engine | Only needed for actual container provisioning. API responds with mock data without Docker. |
| SMTP credentials | Emails queue silently via BullMQ. Nothing crashes. |
| BASE_DOMAIN | Only for production Traefik routing. Defaults to `labs.yourdomain.com`. |
| BullMQ Worker | Run `npm run dev:worker` only if you need labs to advance from `provisioning` to `ready`. |
