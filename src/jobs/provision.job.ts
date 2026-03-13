import { Worker, Job } from 'bullmq';
import { redisClient } from '../config/redis';
import { containerService } from '../services/container.service';
import { db } from '../config/database';
import { sessions } from '../db/schema/sessions';
import { eq } from 'drizzle-orm';
import { publishEvent } from '../utils/publishEvent';
// authService is Phase 4, mock for now
// import { authService } from '../services/auth.service';

const REDIS_URL = process.env.REDIS_URL || 'redis://localhost:6379';

export const provisionWorker = new Worker('provision', async (job: Job) => {
    const { sessionId, labId, userId, dockerImage, initScript, exposePort } = job.data;

    try {
        const containerId = await containerService.createContainer({
            sessionId, userId, image: dockerImage || 'lab-k8s-basics:latest', exposePort
        });
        await containerService.startContainer(containerId);

        let isRunning = false;
        for (let i = 0; i < 60; i++) {
            const info = await containerService.inspectContainer(containerId);
            if (info.running) {
                isRunning = true;
                break;
            }
            await new Promise(res => setTimeout(res, 1000));
        }

        if (!isRunning) {
            throw new Error('Container failed to start within 60s');
        }

        // Generate embed token (to be implemented strictly by Person 2)
        const embedToken = 'mock-embed-token-replace-in-phase-4';

        const baseDomain = process.env.BASE_DOMAIN || 'labs.yourdomain.com';
        const terminal_url = `https://${sessionId}.${baseDomain}/terminal?token=${embedToken}`;

        await db.update(sessions)
            .set({
                status: 'ready',
                terminalUrl: terminal_url,
                readyAt: new Date(),
                containerId: containerId
            })
            .where(eq(sessions.id, sessionId));

        await publishEvent(sessionId, 'session_ready', { terminal_url });

    } catch (err: any) {
        await db.update(sessions)
            .set({ status: 'error', errorMessage: err.message })
            .where(eq(sessions.id, sessionId));

        try {
            await containerService.removeContainer(`lab-${sessionId}`);
        } catch { }

        throw err;
    }
}, { connection: { url: REDIS_URL }, concurrency: 5 });
