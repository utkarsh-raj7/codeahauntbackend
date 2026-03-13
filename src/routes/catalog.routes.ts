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
};

export default catalogRoutes;
