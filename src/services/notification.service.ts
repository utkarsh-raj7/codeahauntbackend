import { publishEvent } from '../utils/publishEvent';
import { Queue } from 'bullmq';

const REDIS_URL = process.env.REDIS_URL || 'redis://localhost:6379';
const emailQueue = new Queue('email', { connection: { url: REDIS_URL } });

type EmailTemplate = 'booking_confirmed' | 'booking_reminder' | 'lab_expired' | 'lab_completed';

export class NotificationService {
    /**
     * Send a real-time WebSocket notification to a user's session.
     */
    async sendWebSocketNotification(
        sessionId: string,
        eventType: string,
        payload: Record<string, unknown>
    ): Promise<void> {
        await publishEvent(sessionId, eventType, payload);
    }

    /**
     * Queue an email notification via BullMQ — NEVER await email directly in an HTTP handler.
     */
    async sendEmailNotification(
        userId: string,
        template: EmailTemplate,
        data: Record<string, unknown>
    ): Promise<void> {
        await emailQueue.add('send-email', {
            userId,
            template,
            data,
            queuedAt: new Date().toISOString(),
        });
    }

    /**
     * Convenience: send both WS + email for important events.
     */
    async notifyLabReady(sessionId: string, userId: string, terminalUrl: string): Promise<void> {
        await this.sendWebSocketNotification(sessionId, 'session_ready', { terminal_url: terminalUrl });
        await this.sendEmailNotification(userId, 'booking_confirmed', {
            sessionId,
            terminalUrl,
        });
    }

    async notifyLabExpired(sessionId: string, userId: string): Promise<void> {
        await this.sendWebSocketNotification(sessionId, 'session_expired', {});
        await this.sendEmailNotification(userId, 'lab_expired', { sessionId });
    }

    async notifyLabCompleted(sessionId: string, userId: string): Promise<void> {
        await this.sendWebSocketNotification(sessionId, 'lab_completed', {});
        await this.sendEmailNotification(userId, 'lab_completed', { sessionId });
    }

    async notifyTimeWarning(sessionId: string, secondsRemaining: number): Promise<void> {
        await this.sendWebSocketNotification(sessionId, 'time_warning', {
            seconds_remaining: secondsRemaining,
        });
    }
}

export const notificationService = new NotificationService();
