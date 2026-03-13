import { FastifyPluginAsync } from 'fastify';
import { authenticate } from '../middleware/authenticate';

const labsRoutes: FastifyPluginAsync = async (app) => {
    app.addHook('preHandler', authenticate);

    // Existing DELETE logic for ending a session
    app.delete('/:sessionId', async (request, reply) => {
        const { sessionId } = request.params as { sessionId: string };
        // orchestrator.destroyLab(sessionId)
        return reply.code(200).send({ status: 'destroyed' });
    });

    // 6.8 Delta: POST /:sessionId/destroy is now required alongside DELETE (sendBeacon compat)
    app.post('/:sessionId/destroy', async (request, reply) => {
        const { sessionId } = request.params as { sessionId: string };
        // Identical logic to DELETE /:sessionId but accepts text/plain body from navigator.sendBeacon
        // orchestrator.destroyLab(sessionId)
        return reply.code(200).send({ status: 'destroyed' });
    });

    // 6.6 Delta: heartbeat endpoint MUST return time_remaining_seconds (field name is locked)
    app.post('/:sessionId/heartbeat', async (request, reply) => {
        const { sessionId } = request.params as { sessionId: string };
        // session.heartbeat(sessionId)
        return reply.code(200).send({ time_remaining_seconds: 3600 });
    });
};

export default labsRoutes;
