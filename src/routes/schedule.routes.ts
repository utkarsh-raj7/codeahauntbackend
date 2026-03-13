import { FastifyPluginAsync } from 'fastify';
import { authenticate } from '../middleware/authenticate';

const scheduleRoutes: FastifyPluginAsync = async (app) => {
    app.addHook('preHandler', authenticate);

    // TODO Phase 6: Call scheduler.service.ts
    app.post('/', async (request, reply) => {
        return reply.code(200).send({ status: 'scheduled' });
    });

    // TODO Phase 6: Call scheduler.service.ts
    app.get('/', async (request, reply) => {
        return reply.code(200).send([]);
    });
};

export default scheduleRoutes;
