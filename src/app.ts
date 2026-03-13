import Fastify, { FastifyInstance } from 'fastify';
import cors from '@fastify/cors';
import helmet from '@fastify/helmet';
import websocket from '@fastify/websocket';
import rateLimit from '@fastify/rate-limit';
import { sql } from 'drizzle-orm';
import { db } from './config/database';
import { redisClient } from './config/redis';

export async function buildApp(): Promise<FastifyInstance> {
    const app = Fastify({ logger: true });

    const frontendUrl = process.env.FRONTEND_URL || 'http://localhost:3000';

    // 1. Register plugins
    await app.register(cors, {
        origin: [
            'http://localhost:3000',    // Next.js dev server
            frontendUrl,                // prod domain
        ],
        methods: ['GET', 'POST', 'DELETE', 'OPTIONS'],
        allowedHeaders: ['Authorization', 'Content-Type'],
        credentials: true,
    });

    await app.register(helmet, {
        contentSecurityPolicy: {
            directives: {
                frameAncestors: ["'self'", frontendUrl],
            },
        },
    });

    await app.register(websocket);

    await app.register(rateLimit, {
        global: false,
    });

    // 2. Health endpoint — liveness probe
    app.get('/health', async () => {
        return { status: 'ok', uptime: process.uptime() };
    });

    // 3. Ready endpoint — readiness probe (returns 503 if DB or Redis is down)
    app.get('/ready', async (_request, reply) => {
        try {
            await db.execute(sql`SELECT 1`);
            const pong = await redisClient.ping();
            if (pong !== 'PONG') throw new Error('Redis not ready');
            return { status: 'ready' };
        } catch (err) {
            app.log.error(err);
            return reply.code(503).send({ status: 'error', message: 'Service Unavailable' });
        }
    });

    return app;
}
