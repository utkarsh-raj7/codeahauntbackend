import { FastifyInstance } from 'fastify';
import { adminAuth } from '../config/firebase-admin';
import * as jwt from 'jsonwebtoken';

const JWT_SECRET = process.env.JWT_SECRET || 'your-256-bit-secret-here';

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

            con.socket.send(JSON.stringify({ type: 'connected', time_remaining_seconds: 3600 }));

            con.socket.on('message', (message) => {
                try {
                    const data = JSON.parse(message.toString());
                    if (data.type === 'heartbeat') {
                        con.socket.send(JSON.stringify({ type: 'heartbeat_ack' }));
                    }
                } catch (e) {
                    // ignore
                }
            });

        } catch (err) {
            con.socket.close(1008, 'Invalid token');
        }
    });
}
