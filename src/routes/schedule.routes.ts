import { FastifyPluginAsync } from 'fastify';
import { authenticate } from '../middleware/authenticate';
import { schedulerService } from '../services/scheduler.service';

const scheduleRoutes: FastifyPluginAsync = async (app) => {
    app.addHook('preHandler', authenticate);

    // Schedule a new lab (generic)
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

    // --- Frontend-expected routes below ---

    // GET /slots — available time slots for a lab on a given date
    app.get('/slots', async (request, reply) => {
        const { labId, date } = request.query as { labId?: string; date?: string };
        // Generate 1-hour slots from 9:00 to 21:00 for the requested date
        const targetDate = date ? new Date(date) : new Date();
        const slots = [];
        for (let hour = 9; hour < 21; hour++) {
            const slotStart = new Date(targetDate);
            slotStart.setHours(hour, 0, 0, 0);
            const slotEnd = new Date(targetDate);
            slotEnd.setHours(hour + 1, 0, 0, 0);
            slots.push({
                id: `slot-${hour}`,
                labId: labId || 'any',
                startTime: slotStart.toISOString(),
                endTime: slotEnd.toISOString(),
                available: slotStart.getTime() > Date.now(), // past slots unavailable
            });
        }
        return reply.code(200).send(slots);
    });

    // POST /book — book a specific slot
    app.post('/book', async (request, reply) => {
        const userId = request.user.sub as string;
        const { labId, slotId, scheduledAt } = request.body as {
            labId: string; slotId: string; scheduledAt: string;
        };
        const result = await schedulerService.scheduleLab(userId, labId, new Date(scheduledAt));
        return reply.code(201).send({ ...result, slotId });
    });

    // GET /my-bookings — get current user's bookings
    app.get('/my-bookings', async (request, reply) => {
        const userId = request.user.sub as string;
        const results = await schedulerService.getScheduledLabs(userId);
        return reply.code(200).send(results);
    });
};

export default scheduleRoutes;
