import { FastifyRequest, FastifyReply } from 'fastify';
import { db } from '../config/database';
import { sessions } from '../db/schema/sessions';
import { eq } from 'drizzle-orm';
import { AppError } from '../types';

export async function ownerGuard(request: FastifyRequest, reply: FastifyReply) {
    const { sessionId } = request.params as { sessionId: string };
    if (!sessionId) {
        throw new AppError('BAD_REQUEST', 'Missing sessionId parameter', 400);
    }

    if (!request.user || !request.user.sub) {
        throw new AppError('UNAUTHORIZED', 'Missing user authentication', 401);
    }

    const sessionRecord = await db.select({ user_id: sessions.userId })
        .from(sessions)
        .where(eq(sessions.id, sessionId));

    if (sessionRecord.length === 0) {
        throw new AppError('SESSION_NOT_FOUND', 'Session not found', 404);
    }

    if (sessionRecord[0].user_id !== request.user.sub) {
        throw new AppError('FORBIDDEN', 'Access denied. You do not own this session.', 403);
    }
}
