import { FastifyPluginAsync } from 'fastify';
import { authenticate } from '../middleware/authenticate';
import { ownerGuard } from '../middleware/ownerGuard';
import { db } from '../config/database';
import { sessions } from '../db/schema/sessions';
import { eq } from 'drizzle-orm';
import { orchestrator } from '../services/orchestrator.service';
import { sessionService } from '../services/session.service';

const labsRoutes: FastifyPluginAsync = async (app) => {
    // 1. Get all sessions for current user (no ownerGuard needed, just authenticate)
    app.get('/sessions', { preHandler: [authenticate] }, async (request, reply) => {
        const userId = request.user.sub as string;
        const userSessions = await db.select().from(sessions).where(eq(sessions.userId, userId));
        return reply.code(200).send(userSessions);
    });

    // 2. Provision a new lab (no ownerGuard needed, just authenticate)
    app.post('/:labId/provision', { preHandler: [authenticate] }, async (request, reply) => {
        const { labId } = request.params as { labId: string };
        const result = await orchestrator.provisionLab(request, labId);
        return reply.code(200).send(result);
    });

    // 3. Get session status
    app.get('/:sessionId/status', { preHandler: [authenticate, ownerGuard] }, async (request, reply) => {
        const { sessionId } = request.params as { sessionId: string };
        const userId = request.user.sub as string;
        const result = await orchestrator.getSessionStatus(sessionId, userId);
        return reply.code(200).send(result);
    });

    // 4. Destroy session
    app.delete('/:sessionId', { preHandler: [authenticate, ownerGuard] }, async (request, reply) => {
        const { sessionId } = request.params as { sessionId: string };
        const result = await orchestrator.destroyLab(sessionId);
        return reply.code(200).send(result);
    });

    // 5. Destroy session (POST alternative for navigator.sendBeacon)
    app.post('/:sessionId/destroy', { preHandler: [authenticate, ownerGuard] }, async (request, reply) => {
        const { sessionId } = request.params as { sessionId: string };
        const result = await orchestrator.destroyLab(sessionId);
        return reply.code(200).send(result);
    });

    // 6. Heartbeat
    app.post('/:sessionId/heartbeat', { preHandler: [authenticate, ownerGuard] }, async (request, reply) => {
        const { sessionId } = request.params as { sessionId: string };
        const userId = request.user.sub as string;
        const result = await sessionService.heartbeat(sessionId, userId);
        return reply.code(200).send(result);
    });
};

export default labsRoutes;
