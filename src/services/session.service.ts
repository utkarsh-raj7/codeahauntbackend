import { db } from '../config/database';
import { sessions } from '../db/schema/sessions';
import { eq, and } from 'drizzle-orm';
import { AppError } from '../types';
import { redisClient } from '../config/redis';

export class SessionService {
    async heartbeat(sessionId: string, userId?: string) {
        // userId check optional here if handled by middleware, but good for defense
        const conditions = userId
            ? and(eq(sessions.id, sessionId), eq(sessions.userId, userId))
            : eq(sessions.id, sessionId);

        const sessionRecord = await db.select().from(sessions).where(conditions);
        if (sessionRecord.length === 0) {
            throw new AppError('SESSION_NOT_FOUND', 'Session not found', 404);
        }

        const DEFAULT_TTL = parseInt(process.env.DEFAULT_SESSION_TTL || '3600', 10);
        await redisClient.set(`sess:${sessionId}`, '1', 'EX', DEFAULT_TTL);

        return { time_remaining_seconds: DEFAULT_TTL };
    }

    async extendSession(sessionId: string, extendBySeconds: number, userId?: string) {
        const conditions = userId
            ? and(eq(sessions.id, sessionId), eq(sessions.userId, userId))
            : eq(sessions.id, sessionId);

        const sessionRecord = await db.select().from(sessions).where(conditions);

        if (sessionRecord.length === 0) {
            throw new AppError('SESSION_NOT_FOUND', 'Session not found', 404);
        }

        const s = sessionRecord[0];
        const MAX_SESSION_TTL = parseInt(process.env.MAX_SESSION_TTL || '14400', 10);

        // Cap from created_at, not from current time
        const absoluteMaxExpiresAt = new Date(s.createdAt.getTime() + MAX_SESSION_TTL * 1000);
        const newExpiresAt = new Date(s.expiresAt.getTime() + extendBySeconds * 1000);

        if (newExpiresAt > absoluteMaxExpiresAt) {
            // Alternatively, could cap it instead of throwing, but requirement says:
            // "if it caps from now, a user can extend indefinitely"
            // We'll throw an error if the requested extension pushes past absolute max
            throw new AppError('MAX_TTL_EXCEEDED', `Cannot extend beyond max TTL of ${MAX_SESSION_TTL}s from creation`, 400);
        }

        const newTtlSeconds = Math.max(0, Math.floor((newExpiresAt.getTime() - Date.now()) / 1000));

        await db.update(sessions)
            .set({ expiresAt: newExpiresAt })
            .where(eq(sessions.id, sessionId));

        await redisClient.set(`sess:${sessionId}`, '1', 'EX', newTtlSeconds);

        return { status: 'extended', expires_at: newExpiresAt, time_remaining_seconds: newTtlSeconds };
    }
}

export const sessionService = new SessionService();
