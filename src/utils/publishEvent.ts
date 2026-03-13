import { redisClient } from '../config/redis';

// 6.1 WS Gateway publishEvent signature
export async function publishEvent(sessionId: string, type: string, payload: any) {
    const event = { type, ...payload };
    await redisClient.publish(`lab:${sessionId}:events`, JSON.stringify(event));
}
