import { FastifyPluginAsync } from 'fastify';
import { z } from 'zod';
import { authService } from '../services/auth.service';
import { db } from '../config/database';
import { users } from '../db/schema/users';
import { eq } from 'drizzle-orm';
import { AppError } from '../types';
import { authenticate } from '../middleware/authenticate';

const authRoutes: FastifyPluginAsync = async (app) => {
    // 5 requests per IP per 60s
    app.post('/login', {
        config: {
            rateLimit: {
                max: 5,
                timeWindow: '60s'
            }
        }
    }, async (request, reply) => {
        const bodySchema = z.object({ email: z.string().email(), password: z.string() });
        const { email, password } = bodySchema.parse(request.body);

        // Load user by email
        const userRecords = await db.select().from(users).where(eq(users.email, email));
        const user = userRecords[0];

        if (!user) {
            throw new AppError('INVALID_CREDENTIALS', 'Invalid email or password', 401);
        }

        const isValid = await authService.verifyPassword(password, user.passwordHash);
        if (!isValid) {
            throw new AppError('INVALID_CREDENTIALS', 'Invalid email or password', 401);
        }

        const accessToken = await authService.issueAccessToken(user.id, user.role);
        const refreshToken = await authService.issueRefreshToken(user.id);

        await db.update(users)
            .set({ lastLogin: new Date() })
            .where(eq(users.id, user.id));

        return reply.code(200).send({
            access_token: accessToken,
            refresh_token: refreshToken
        });
    });

    app.post('/refresh', async (request, reply) => {
        const bodySchema = z.object({ refresh_token: z.string() });
        const { refresh_token } = bodySchema.parse(request.body);

        const tokens = await authService.refreshTokens(refresh_token);

        return reply.code(200).send({
            access_token: tokens.accessToken,
            refresh_token: tokens.newRefreshToken
        });
    });

    app.post('/logout', { preHandler: [authenticate] }, async (request, reply) => {
        const userId = request.user.sub;
        await authService.revokeAllUserTokens(userId);
        return reply.code(200).send({ status: 'ok' });
    });
};

export default authRoutes;
