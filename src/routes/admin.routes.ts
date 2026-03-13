import { FastifyPluginAsync, FastifyRequest, FastifyReply } from 'fastify';
import { authenticate } from '../middleware/authenticate';

async function adminOnly(req: FastifyRequest, reply: FastifyReply) {
    if (req.user.role !== 'admin') {
        return reply.code(403).send({
            error: { code: 'FORBIDDEN', message: 'Admin only', http_status: 403 }
        });
    }
}

const adminRoutes: FastifyPluginAsync = async (app) => {
    // Admin dashboard / metrics endpoint example
    app.get('/metrics', { preHandler: [authenticate, adminOnly] }, async (request, reply) => {
        return reply.code(200).send({ status: 'ok', metrics: {} });
    });
};

export default adminRoutes;
