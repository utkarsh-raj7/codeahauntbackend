import { FastifyPluginAsync } from 'fastify';
import { z } from 'zod';

const authRoutes: FastifyPluginAsync = async (app) => {
    // 6.1 Delta: Remove POST /auth/register — user registration is handled by Firebase on the frontend.

    // Keep POST /auth/login — used for service accounts and test tooling only
    app.post('/login', async (request, reply) => {
        const bodySchema = z.object({ email: z.string(), password: z.string() });
        const { email, password } = bodySchema.parse(request.body);
        return reply.code(200).send({ message: 'login endpoint kept for test tooling/service accounts' });
    });

    // Keep POST /auth/refresh for internal JWT cleanup
    app.post('/refresh', async (request, reply) => {
        return reply.code(200).send({ message: 'refresh endpoint kept' });
    });

    // Keep POST /auth/logout for internal JWT cleanup
    app.post('/logout', async (request, reply) => {
        return reply.code(200).send({ message: 'logout endpoint kept' });
    });
};

export default authRoutes;
