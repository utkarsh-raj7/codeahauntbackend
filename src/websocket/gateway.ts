import { FastifyInstance } from 'fastify';
import { adminAuth } from '../config/firebase-admin';
import * as jwt from 'jsonwebtoken';
import { sessionService } from '../services/session.service';
import { redisClient } from '../config/redis';

const JWT_SECRET = process.env.JWT_SECRET || 'your-256-bit-secret-here';
const TIME_WARNING_THRESHOLD = 300; // 5 minutes in seconds

export async function setupWebSocketGateway(app: FastifyInstance) {
    app.get('/ws/v1/labs/:sessionId/events', { websocket: true }, async (con, req) => {
        const { sessionId } = req.params as { sessionId: string };

        // 6.5 WS Auth — Subprotocol
        // Token extraction order: Sec-WebSocket-Protocol header first, ?token= fallback
        let token: string | null = null;
        const protocol = req.headers['sec-websocket-protocol'];

        if (protocol) {
            // Header: 'Bearer, <token>'  →  split by comma, find non-'Bearer' part
            const parts = protocol.split(',').map(p => p.trim());
            token = parts.find(p => p !== 'Bearer') ?? null;
        }

        if (!token) {
            const query = req.query as { token?: string };
            token = query.token ?? null;
        }

        if (!token) {
            con.socket.close(1008, 'Token missing');
            return;
        }

        try {
            // Check Firebase first, then fallback to internal JWT
            let userId: string | null = null;
            if (adminAuth) {
                try {
                    const decoded = await adminAuth.verifyIdToken(token);
                    userId = decoded.uid;
                } catch {
                    // Fallback to internal JWT
                }
            }

            if (!userId) {
                const decoded = jwt.verify(token, JWT_SECRET) as jwt.JwtPayload;
                userId = decoded.sub as string;
            }

            // Get initial TTL from Redis
            const ttl = await redisClient.ttl(`sess:${sessionId}`);
            const timeRemaining = ttl > 0 ? ttl : 3600;

            con.socket.send(JSON.stringify({
                type: 'connected',
                time_remaining_seconds: timeRemaining,
                ts: Date.now(),
            }));

            // Time warning check interval — poll Redis TTL every 30s
            const warningInterval = setInterval(async () => {
                try {
                    const currentTtl = await redisClient.ttl(`sess:${sessionId}`);
                    if (currentTtl > 0 && currentTtl <= TIME_WARNING_THRESHOLD) {
                        con.socket.send(JSON.stringify({
                            type: 'time_warning',
                            minutes_remaining: Math.ceil(currentTtl / 60),
                            ts: Date.now(),
                        }));
                    }
                    if (currentTtl <= 0) {
                        con.socket.send(JSON.stringify({
                            type: 'session_expired',
                            reason: 'ttl_reached',
                            ts: Date.now(),
                        }));
                        con.socket.close(1000, 'Session expired');
                    }
                } catch {
                    // Redis unavailable — don't crash the WS
                }
            }, 30000);

            // Message handler
            con.socket.on('message', async (message: Buffer | string) => {
                try {
                    const data = JSON.parse(message.toString());
                    if (data.type === 'heartbeat') {
                        // Real heartbeat — resets Redis TTL via sessionService
                        const result = await sessionService.heartbeat(sessionId, userId!);
                        con.socket.send(JSON.stringify({
                            type: 'heartbeat_ack',
                            time_remaining_seconds: result.time_remaining_seconds,
                            ts: Date.now(),
                        }));
                    }
                } catch {
                    // Ignore malformed messages
                }
            });

            // Cleanup on close
            con.socket.on('close', () => {
                clearInterval(warningInterval);
            });

        } catch {
            con.socket.close(1008, 'Invalid token');
        }
    });
}

