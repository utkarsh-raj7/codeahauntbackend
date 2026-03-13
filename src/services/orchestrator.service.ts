import { FastifyRequest } from 'fastify';
import { db } from '../config/database';
import { sessions } from '../db/schema/sessions';
import { eq, and, notInArray, desc } from 'drizzle-orm';
import { containerService } from './container.service';
import { AppError } from '../types';
import { Queue } from 'bullmq';
import { redisClient } from '../config/redis';
import { publishEvent } from '../utils/publishEvent';
import { randomUUID } from 'crypto';

const REDIS_URL = process.env.REDIS_URL || 'redis://localhost:6379';
export const provisionQueue = new Queue('provision', { connection: { url: REDIS_URL } });

const KEEP_RECENT = parseInt(process.env.KEEP_RECENT_SESSIONS || '3', 10);

export class OrchestratorService {
    async provisionLab(req: FastifyRequest | any, labId: string, options: any = {}) {
        const userId = req.user?.sub || req.userId; // Support both forms
        if (!userId) throw new AppError('UNAUTHORIZED', 'Missing user ID', 401);

        const MAX_ACTIVE = parseInt(process.env.MAX_ACTIVE_SESSIONS_PER_USER || '100', 10);
        const MAX_TOTAL = parseInt(process.env.MAX_TOTAL_ACTIVE_CONTAINERS || '500', 10);
        const DEFAULT_TTL = parseInt(process.env.DEFAULT_SESSION_TTL || '3600', 10);

        // 0. Prune old sessions first (keeps KEEP_RECENT, frees quota)
        await this.pruneOldSessions(userId).catch(err =>
            console.warn('[auto-prune] Non-blocking prune error:', err.message)
        );

        // 1. Quota check specific user
        const userSessions = await db.select().from(sessions).where(
            and(eq(sessions.userId, userId), eq(sessions.status, 'ready'))
        );
        if (userSessions.length >= MAX_ACTIVE) {
            throw new AppError('QUOTA_EXCEEDED', `Max ${MAX_ACTIVE} sessions allowed`, 403);
        }

        // 2. Idempotency Check
        const existing = await db.select().from(sessions).where(
            and(eq(sessions.userId, userId), eq(sessions.labId, labId))
        );
        const activeExisting = existing.find(s => ['provisioning', 'ready'].includes(s.status));
        if (activeExisting) return activeExisting;

        // 3. Global Capacity
        const allContainers = await containerService.listLabContainers();
        if (allContainers.length >= MAX_TOTAL) {
            throw new AppError('LAB_CAPACITY_FULL', 'System at maximum capacity', 503);
        }

        const sessionId = randomUUID();
        const baseDomain = process.env.BASE_DOMAIN || 'labs.yourdomain.com';

        // 4. SET Redis key (acquire lock first)
        await redisClient.set(`sess:${sessionId}`, '1', 'EX', DEFAULT_TTL);

        // 5. Insert DB
        await db.insert(sessions).values({
            id: sessionId,
            userId,
            labId,
            status: 'provisioning',
            subdomain: `${sessionId}.${baseDomain}`,
            ttlSeconds: DEFAULT_TTL,
            expiresAt: new Date(Date.now() + DEFAULT_TTL * 1000)
        });

        // 6. Enqueue job
        await provisionQueue.add('provision-lab', {
            sessionId,
            labId,
            userId,
            dockerImage: options.dockerImage,
            initScript: options.initScript,
            exposePort: options.exposePort || 7681
        }); // Failsafe timeout handled within worker logic

        // 7. Return record
        return {
            session_id: sessionId,
            userId,
            labId,
            status: 'provisioning',
            expiresAt: new Date(Date.now() + DEFAULT_TTL * 1000)
        };
    }

    /**
     * Auto-prune: keep only the N most recent sessions per user.
     * Older containers are stopped, removed, and marked 'destroyed'.
     * Runs in a non-blocking fashion so new provisions are never delayed.
     */
    async pruneOldSessions(userId: string) {
        const activeSessions = await db.select().from(sessions).where(
            and(
                eq(sessions.userId, userId),
                notInArray(sessions.status, ['destroyed', 'expired'])
            )
        );

        if (activeSessions.length <= KEEP_RECENT) return; // nothing to prune

        // Sort newest-first by createdAt
        activeSessions.sort((a, b) =>
            new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime()
        );

        const toPrune = activeSessions.slice(KEEP_RECENT);
        console.log(`[auto-prune] User ${userId.slice(0, 8)}: pruning ${toPrune.length} old session(s), keeping ${KEEP_RECENT}`);

        for (const session of toPrune) {
            try {
                if (session.containerId) {
                    await containerService.stopContainer(session.containerId).catch(() => { });
                    await containerService.removeContainer(session.containerId).catch(() => { });
                }
                await redisClient.del(`sess:${session.id}`);
                await db.update(sessions)
                    .set({ status: 'destroyed', endedAt: new Date() })
                    .where(eq(sessions.id, session.id));
                console.log(`[auto-prune] Destroyed session ${session.id.slice(0, 8)} (lab: ${session.labId})`);
            } catch (err: any) {
                console.warn(`[auto-prune] Failed to prune ${session.id.slice(0, 8)}:`, err.message);
            }
        }
    }

    async destroyLab(sessionId: string) {
        const sessionRecord = await db.select().from(sessions).where(eq(sessions.id, sessionId));
        if (!sessionRecord || sessionRecord.length === 0) {
            throw new AppError('SESSION_NOT_FOUND', 'Session not found', 404);
        }

        const s = sessionRecord[0];
        if (s.status === 'destroyed') return { status: 'destroyed' };

        // Stop + Remove
        if (s.containerId) {
            try {
                await containerService.stopContainer(s.containerId);
                await containerService.removeContainer(s.containerId);
            } catch (err: any) {
                console.warn(`Could not completely remove container for session ${sessionId}:`, err);
            }
        }

        await redisClient.del(`sess:${sessionId}`);

        await db.update(sessions)
            .set({ status: 'destroyed', endedAt: new Date() })
            .where(eq(sessions.id, sessionId));

        await publishEvent(sessionId, 'session_expired', {});

        return { status: 'destroyed' };
    }

    async getSessionStatus(sessionId: string, userId: string) {
        const sessionRecord = await db.select().from(sessions).where(eq(sessions.id, sessionId));
        if (!sessionRecord || sessionRecord.length === 0) {
            throw new AppError('SESSION_NOT_FOUND', 'Session not found', 404);
        }
        const s = sessionRecord[0];
        if (s.userId !== userId) {
            throw new AppError('FORBIDDEN', 'Access denied', 403);
        }

        return { status: s.status, terminal_url: s.terminalUrl };
    }
}

export const orchestrator = new OrchestratorService();

