import { FastifyPluginAsync } from 'fastify';
import { authenticate } from '../middleware/authenticate';
import { schedulerService } from '../services/scheduler.service';

const scheduleRoutes: FastifyPluginAsync = async (app) => {
    app.addHook('preHandler', authenticate);

    // Schedule a new lab
    app.post('/', async (request, reply) => {
        const userId = request.user.sub as string;
        const { labId, scheduledAt } = request.body as { labId: string; scheduledAt: string };
        const result = await schedulerService.scheduleLab(userId, labId, new Date(scheduledAt));
        return reply.code(201).send(result);
    });

    // Get user's scheduled labs
    app.get('/', async (request, reply) => {
        const userId = request.user.sub as string;
        const results = await schedulerService.getScheduledLabs(userId);
        return reply.code(200).send(results);
    });

    // Cancel a scheduled lab
    app.delete('/:scheduleId', async (request, reply) => {
        const userId = request.user.sub as string;
        const { scheduleId } = request.params as { scheduleId: string };
        await schedulerService.cancelScheduledLab(scheduleId, userId);
        return reply.code(200).send({ status: 'cancelled' });
    });
};

export default scheduleRoutes;
