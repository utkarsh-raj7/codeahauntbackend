import { Worker, Job } from 'bullmq';
import { db } from '../config/database';
import { sessions } from '../db/schema/sessions';
import { lt, and, notInArray, eq } from 'drizzle-orm';
import { orchestrator } from '../services/orchestrator.service';

const REDIS_URL = process.env.REDIS_URL || 'redis://localhost:6379';

export const cleanupWorker = new Worker('cleanup', async (job: Job) => {
    const expiredSessions = await db.select()
        .from(sessions)
        .where(
            and(
                lt(sessions.expiresAt, new Date()),
                notInArray(sessions.status, ['destroyed', 'expired'])
            )
        );

    for (const session of expiredSessions) {
        try {
            await orchestrator.destroyLab(session.id);
            await db.update(sessions)
                .set({ status: 'expired' })
                .where(eq(sessions.id, session.id));
        } catch (err) {
            console.error(`Failed to cleanup session ${session.id}:`, err);
        }
    }
}, { connection: { url: REDIS_URL } });
