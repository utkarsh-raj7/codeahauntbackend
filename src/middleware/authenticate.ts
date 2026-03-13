import { FastifyRequest, FastifyReply } from 'fastify';
import { adminAuth } from '../config/firebase-admin';
import * as jwt from 'jsonwebtoken';

// Extend Fastify request to carry user info
declare module 'fastify' {
    interface FastifyRequest {
        user: {
            sub: string;
            role: string;
            type: 'firebase' | 'internal';
            scope?: string;
            session_id?: string;
        };
    }
}

const JWT_SECRET = process.env.JWT_SECRET || 'your-256-bit-secret-here';

export async function authenticate(request: FastifyRequest, reply: FastifyReply) {
    const authHeader = request.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
        return reply.code(401).send({
            error: { code: 'UNAUTHORIZED', message: 'Missing or invalid Authorization header', http_status: 401 }
        });
    }

    const token = authHeader.slice(7);

    // ── Path 1: Try Firebase ID token first ──
    if (adminAuth) {
        try {
            const decoded = await adminAuth.verifyIdToken(token);

            // Reject embed tokens (should never come from Firebase, but enforce anyway)
            if ((decoded as Record<string, unknown>).scope === 'embed') {
                return reply.code(401).send({
                    error: { code: 'UNAUTHORIZED', message: 'Embed tokens are not accepted on API routes', http_status: 401 }
                });
            }

            request.user = {
                sub: decoded.uid,
                role: (decoded as Record<string, unknown>).role as string || 'student',
                type: 'firebase'
            };
            return;
        } catch {
            // Firebase verification failed — fall through to internal JWT path
        }
    }

    // ── Path 2: Internal JWT fallback (service-to-service, tests) ──
    try {
        const decoded = jwt.verify(token, JWT_SECRET) as jwt.JwtPayload;

        // LOCKED: Embed tokens (scope: 'embed') are ALWAYS rejected on REST routes
        if (decoded.scope === 'embed') {
            return reply.code(401).send({
                error: { code: 'UNAUTHORIZED', message: 'Embed tokens are not accepted on API routes', http_status: 401 }
            });
        }

        // Check if token has expired
        if (decoded.exp && decoded.exp * 1000 < Date.now()) {
            return reply.code(401).send({
                error: { code: 'TOKEN_EXPIRED', message: 'Token has expired', http_status: 401 }
            });
        }

        request.user = {
            sub: decoded.sub as string,
            role: decoded.role as string || 'student',
            type: 'internal',
            scope: decoded.scope as string | undefined,
            session_id: decoded.session_id as string | undefined
        };
        return;
    } catch (err) {
        if (err instanceof jwt.TokenExpiredError) {
            return reply.code(401).send({
                error: { code: 'TOKEN_EXPIRED', message: 'Token has expired', http_status: 401 }
            });
        }
        return reply.code(401).send({
            error: { code: 'UNAUTHORIZED', message: 'Invalid token', http_status: 401 }
        });
    }
}
