import { Worker, Job, Queue } from 'bullmq';
import { containerService } from '../services/container.service';
import { authService } from '../services/auth.service';
import { db } from '../config/database';
import { sessions } from '../db/schema/sessions';
import { labs } from '../db/schema/labs';
import { eq } from 'drizzle-orm';
import { publishEvent } from '../utils/publishEvent';

const REDIS_URL = process.env.REDIS_URL || 'redis://localhost:6379';
const tokenRefreshQueue = new Queue('token-refresh', { connection: { url: REDIS_URL } });

export const provisionWorker = new Worker('provision', async (job: Job) => {
    const { sessionId, labId, userId, dockerImage, initScript, exposePort } = job.data;

    try {
        // Fetch lab definition from DB for correct docker image
        const labRecord = await db.select().from(labs).where(eq(labs.id, labId));
        const lab = labRecord[0];
        const image = dockerImage || lab?.dockerImage || 'lab-k8s-basics:latest';
        const port = exposePort || lab?.exposePort || 7681;

        const containerId = await containerService.createContainer({
            sessionId, userId, image, exposePort: port
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

        // Real embed token via authService
        const embedToken = await authService.issueEmbedToken(sessionId, userId);

        let terminal_url: string;
        const isDev = process.env.NODE_ENV !== 'production';

        if (isDev) {
            // In dev, resolve the host port Docker assigned to ttyd
            const inspectData = await containerService.inspectContainer(containerId);
            const portKey = `${exposePort || 7681}/tcp`;
            const hostPort = inspectData.ports?.[portKey]?.[0]?.HostPort || '7681';
            terminal_url = `http://localhost:${hostPort}`;
        } else {
            const baseDomain = process.env.BASE_DOMAIN || 'labs.yourdomain.com';
            terminal_url = `https://${sessionId}.${baseDomain}/terminal?token=${embedToken}`;
        }

        await db.update(sessions)
            .set({
                status: 'ready',
                terminalUrl: terminal_url,
                readyAt: new Date(),
                containerId: containerId
            })
            .where(eq(sessions.id, sessionId));

        await publishEvent(sessionId, 'session_ready', { terminal_url });

        // Schedule token refresh — re-issue embed token every 9 minutes
        await tokenRefreshQueue.add('refresh-embed-token',
            { sessionId, userId },
            { delay: 9 * 60 * 1000, repeat: { every: 9 * 60 * 1000 } }
        );

    } catch (err: any) {
        await db.update(sessions)
            .set({ status: 'error', errorMessage: err.message })
            .where(eq(sessions.id, sessionId));

        try {
            await containerService.removeContainer(`lab-${sessionId}`);
        } catch { /* cleanup best-effort */ }

        throw err;
    }
}, { connection: { url: REDIS_URL }, concurrency: 5 });
