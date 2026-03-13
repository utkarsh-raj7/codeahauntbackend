import { Worker, Job } from 'bullmq';
import { db } from '../config/database';
import { sessions } from '../db/schema/sessions';
import { eq } from 'drizzle-orm';
import { containerService } from '../services/container.service';
import { publishEvent } from '../utils/publishEvent';

const REDIS_URL = process.env.REDIS_URL || 'redis://localhost:6379';

export const monitorWorker = new Worker('monitor', async (job: Job) => {
    const activeSessions = await db.select().from(sessions).where(eq(sessions.status, 'ready'));

    for (const session of activeSessions) {
        if (!session.containerId) continue;
        try {
            const stats = await containerService.getContainerStats(session.containerId);

            // Insert into resource_snapshots would go here
            if (stats.cpu_percent > 90) {
                await publishEvent(session.id, 'resource_warning', {
                    cpu_percent: stats.cpu_percent,
                    memory_mb: stats.memory_mb
                });
            }
        } catch (err) {
            console.error(`Monitor failed for session ${session.id}:`, err);
        }
    }
}, { connection: { url: REDIS_URL } });
