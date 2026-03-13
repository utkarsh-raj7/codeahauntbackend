import { FastifyPluginAsync } from 'fastify';
import { db } from '../config/database';
import { labs } from '../db/schema/labs';
import { redisClient } from '../config/redis';
import { eq } from 'drizzle-orm';

const catalogRoutes: FastifyPluginAsync = async (app) => {
    app.get('/labs', async (request, reply) => {
        const query = request.query as { page?: string, limit?: string };
        const page = parseInt(query.page || '1', 10);
        const limit = parseInt(query.limit || '10', 10);
        const cacheKey = `catalog:labs:page:${page}:limit:${limit}`;

        const cached = await redisClient.get(cacheKey);
        if (cached) {
            return reply.code(200).send(JSON.parse(cached));
        }

        const offset = (page - 1) * limit;

        // Fetch active labs with pagination
        const labRecords = await db.select()
            .from(labs)
            .where(eq(labs.isActive, true))
            .limit(limit)
            .offset(offset);

        await redisClient.set(cacheKey, JSON.stringify(labRecords), 'EX', 300); // 5 min TTL
        return reply.code(200).send(labRecords);
    });

    // GET /labs/:labId — single lab definition with steps
    app.get('/labs/:labId', async (request, reply) => {
        const { labId } = request.params as { labId: string };
        const cacheKey = `catalog:lab:${labId}`;

        const cached = await redisClient.get(cacheKey);
        if (cached) {
            return reply.code(200).send(JSON.parse(cached));
        }

        const labRecord = await db.select().from(labs).where(eq(labs.id, labId));
        if (!labRecord.length) {
            return reply.code(404).send({ error: { code: 'LAB_NOT_FOUND', message: 'Lab not found', http_status: 404 } });
        }

        await redisClient.set(cacheKey, JSON.stringify(labRecord[0]), 'EX', 300);
        return reply.code(200).send(labRecord[0]);
    });
};

export default catalogRoutes;
