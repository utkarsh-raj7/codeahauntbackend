import { FastifyPluginAsync } from 'fastify';
import { db } from '../config/database';
import { labs } from '../db/schema/labs';

const catalogRoutes: FastifyPluginAsync = async (app) => {
    app.get('/labs', async (request, reply) => {
        const labRecords = await db.select().from(labs);
        return reply.code(200).send(labRecords);
    });
};

export default catalogRoutes;
