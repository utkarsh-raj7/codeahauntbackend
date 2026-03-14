import { FastifyPluginAsync } from 'fastify';
import { authenticate } from '../middleware/authenticate';
import { ownerGuard } from '../middleware/ownerGuard';
import { db } from '../config/database';
import { sessions } from '../db/schema/sessions';
import { labs } from '../db/schema/labs';
import { eq } from 'drizzle-orm';
import { orchestrator } from '../services/orchestrator.service';
import { sessionService } from '../services/session.service';
import { validationService } from '../services/validation.service';

const labsRoutes: FastifyPluginAsync = async (app) => {
    // 1. Get all sessions for current user
    app.get('/sessions', { preHandler: [authenticate] }, async (request, reply) => {
        const userId = request.user.sub as string;
        const userSessions = await db.select().from(sessions).where(eq(sessions.userId, userId));
        return reply.code(200).send(userSessions);
    });

    // 2. Provision a new lab
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

    // 5. Destroy session (POST — sendBeacon compat)
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

    // 7. Extend session TTL
    app.post('/:sessionId/extend', { preHandler: [authenticate, ownerGuard] }, async (request, reply) => {
        const { sessionId } = request.params as { sessionId: string };
        const userId = request.user.sub as string;
        const { extendBySeconds } = request.body as { extendBySeconds?: number };
        const result = await sessionService.extendSession(sessionId, extendBySeconds || 1800, userId);
        return reply.code(200).send(result);
    });

    // 8. Validate a lab step (container_id always from DB, never from request)
    app.post('/:sessionId/validate/:stepId', { preHandler: [authenticate, ownerGuard] }, async (request, reply) => {
        const { sessionId, stepId } = request.params as { sessionId: string; stepId: string };

        // Look up the lab definition to get the validation command for this step
        const sessionRecord = await db.select().from(sessions).where(eq(sessions.id, sessionId));
        if (!sessionRecord.length) return reply.code(404).send({ error: { code: 'SESSION_NOT_FOUND', message: 'Session not found', http_status: 404 } });

        const labRecord = await db.select().from(labs).where(eq(labs.id, sessionRecord[0].labId));
        if (!labRecord.length) return reply.code(404).send({ error: { code: 'LAB_NOT_FOUND', message: 'Lab not found', http_status: 404 } });

        const labSteps = labRecord[0].steps as Array<{ id: string; validation_cmd: string }> | null;
        const step = labSteps?.find(s => s.id === stepId);
        if (!step) return reply.code(404).send({ error: { code: 'STEP_NOT_FOUND', message: 'Step not found', http_status: 404 } });

        const result = await validationService.validateStep(sessionId, stepId, step.validation_cmd);
        return reply.code(200).send(result);
    });

    // 9. Get session progress (which steps have been validated)
    app.get('/:sessionId/progress', { preHandler: [authenticate, ownerGuard] }, async (request, reply) => {
        const { sessionId } = request.params as { sessionId: string };

        const sessionRecord = await db.select().from(sessions).where(eq(sessions.id, sessionId));
        if (!sessionRecord.length) return reply.code(404).send({ error: { code: 'SESSION_NOT_FOUND', message: 'Session not found', http_status: 404 } });

        const labRecord = await db.select().from(labs).where(eq(labs.id, sessionRecord[0].labId));
        const labSteps = (labRecord[0]?.steps as Array<{ id: string; name: string }>) || [];

        // Return step definitions with completion status placeholder
        // Full progress tracking (per-user step completion) is a Phase 7 DB table
        return reply.code(200).send({
            sessionId,
            labId: sessionRecord[0].labId,
            steps: labSteps.map(s => ({ id: s.id, name: s.name, completed: false })),
            completedCount: 0,
            totalCount: labSteps.length,
        });
    });

    // 10. List files in the session's downloads folder
    app.get('/:sessionId/files', { preHandler: [authenticate, ownerGuard] }, async (request, reply) => {
        const { sessionId } = request.params as { sessionId: string };
        const { containerService } = await import('../services/container.service');
        const volumePath = containerService.getSessionVolumePath(sessionId);

        const { existsSync, readdirSync, statSync } = await import('fs');
        const { join } = await import('path');

        if (!existsSync(volumePath)) {
            return reply.code(200).send({ files: [], hint: 'Save files to ~/downloads inside the lab to see them here.' });
        }

        const files = readdirSync(volumePath).map(name => {
            const stat = statSync(join(volumePath, name));
            return { name, size: stat.size, isDirectory: stat.isDirectory(), modified: stat.mtime };
        });

        return reply.code(200).send({ files, volumePath });
    });

    // 11. Download a file from the session's downloads folder
    app.get('/:sessionId/files/:filename', { preHandler: [authenticate, ownerGuard] }, async (request, reply) => {
        const { sessionId, filename } = request.params as { sessionId: string; filename: string };
        const { containerService } = await import('../services/container.service');
        const volumePath = containerService.getSessionVolumePath(sessionId);

        const { existsSync, createReadStream } = await import('fs');
        const { join, basename } = await import('path');

        // Security: prevent path traversal
        const safeName = basename(filename);
        const filePath = join(volumePath, safeName);

        if (!existsSync(filePath)) {
            return reply.code(404).send({ error: { code: 'FILE_NOT_FOUND', message: `File '${safeName}' not found in downloads`, http_status: 404 } });
        }

        reply.header('Content-Disposition', `attachment; filename="${safeName}"`);
        reply.header('Content-Type', 'application/octet-stream');
        return reply.send(createReadStream(filePath));
    });
};

export default labsRoutes;

