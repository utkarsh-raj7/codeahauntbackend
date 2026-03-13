import { Worker, Job } from 'bullmq';
import { authService } from '../services/auth.service';
import { db } from '../config/database';
import { sessions } from '../db/schema/sessions';
import { eq } from 'drizzle-orm';
import { publishEvent } from '../utils/publishEvent';

const REDIS_URL = process.env.REDIS_URL || 'redis://localhost:6379';
const BASE_DOMAIN = process.env.BASE_DOMAIN || 'labs.yourdomain.com';

export const tokenRefreshWorker = new Worker('token-refresh', async (job: Job) => {
    const { sessionId, userId } = job.data;

    // Check if session is still active
    const sessionRecord = await db.select().from(sessions).where(eq(sessions.id, sessionId));
    if (!sessionRecord.length) return;

    const s = sessionRecord[0];
    if (s.status !== 'ready') return; // Only refresh for active sessions

    // Re-issue embed token
    const newToken = await authService.issueEmbedToken(sessionId, userId);
    const newUrl = `https://${sessionId}.${BASE_DOMAIN}/terminal?token=${newToken}`;

    // Update terminal_url in DB
    await db.update(sessions)
        .set({ terminalUrl: newUrl })
        .where(eq(sessions.id, sessionId));

    // Notify frontend via WebSocket
    await publishEvent(sessionId, 'token_refresh', { terminal_url: newUrl });

}, { connection: { url: REDIS_URL } });
