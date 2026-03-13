import Fastify, { FastifyInstance, FastifyRequest, FastifyReply } from 'fastify';
import cors from '@fastify/cors';
import helmet from '@fastify/helmet';
import websocket from '@fastify/websocket';
import rateLimit from '@fastify/rate-limit';
import { sql } from 'drizzle-orm';
import { db } from './config/database';
import { redisClient } from './config/redis';
import { setupErrorHandler } from './middleware/errorHandler';

import authRoutes from './routes/auth.routes';
import labsRoutes from './routes/labs.routes';
import catalogRoutes from './routes/catalog.routes';
import scheduleRoutes from './routes/schedule.routes';
import adminRoutes from './routes/admin.routes';

export async function buildApp(): Promise<FastifyInstance> {
    const app = Fastify({ logger: true });

    const frontendUrl = process.env.FRONTEND_URL || 'http://localhost:3000';

    // Register primary routes
    await app.register(authRoutes, { prefix: '/api/v1/auth' });
    await app.register(labsRoutes, { prefix: '/api/v1/labs' });
    await app.register(catalogRoutes, { prefix: '/api/v1/catalog' });
    await app.register(scheduleRoutes, { prefix: '/api/v1/schedule' });
    await app.register(adminRoutes, { prefix: '/api/v1/admin' });

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
    app.get('/ready', async (_request: FastifyRequest, reply: FastifyReply) => {
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

    // 4. Global Error Handler Registration
    setupErrorHandler(app);

    return app;
}
