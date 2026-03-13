import { db } from '../config/database';
import { labs } from '../db/schema/labs';
import { eq } from 'drizzle-orm';
import { orchestrator } from './orchestrator.service';
import { AppError } from '../types';
import { Queue } from 'bullmq';

const REDIS_URL = process.env.REDIS_URL || 'redis://localhost:6379';
const notificationQueue = new Queue('notification', { connection: { url: REDIS_URL } });

export interface ScheduledLab {
    id?: string;
    userId: string;
    labId: string;
    scheduledAt: Date;
    status: 'pending' | 'triggered' | 'cancelled';
}

// In-memory store for now; Phase 7 would move this to a DB table
const scheduledLabs: Map<string, ScheduledLab> = new Map();

export class SchedulerService {
    /**
     * Schedule a lab to be provisioned at a future time.
     */
    async scheduleLab(userId: string, labId: string, scheduledAt: Date): Promise<ScheduledLab> {
        // Validate the lab exists
        const labRecord = await db.select().from(labs).where(eq(labs.id, labId));
        if (!labRecord || labRecord.length === 0) {
            throw new AppError('LAB_NOT_FOUND', 'Lab not found', 404);
        }

        if (scheduledAt.getTime() <= Date.now()) {
            throw new AppError('INVALID_SCHEDULE', 'Scheduled time must be in the future', 400);
        }

        const id = crypto.randomUUID();
        const entry: ScheduledLab = {
            id,
            userId,
            labId,
            scheduledAt,
            status: 'pending',
        };

        scheduledLabs.set(id, entry);

        // Queue a delayed notification email
        const delayMs = scheduledAt.getTime() - Date.now() - 5 * 60 * 1000; // 5 min before
        if (delayMs > 0) {
            await notificationQueue.add('schedule-reminder', {
                userId,
                labId,
                scheduledAt: scheduledAt.toISOString(),
            }, { delay: delayMs });
        }

        return entry;
    }

    /**
     * Get all scheduled labs for a given user.
     */
    async getScheduledLabs(userId: string): Promise<ScheduledLab[]> {
        const results: ScheduledLab[] = [];
        for (const entry of scheduledLabs.values()) {
            if (entry.userId === userId && entry.status === 'pending') {
                results.push(entry);
            }
        }
        return results;
    }

    /**
     * Cancel a scheduled lab.
     */
    async cancelScheduledLab(scheduleId: string, userId: string): Promise<void> {
        const entry = scheduledLabs.get(scheduleId);
        if (!entry) {
            throw new AppError('SCHEDULE_NOT_FOUND', 'Scheduled lab not found', 404);
        }
        if (entry.userId !== userId) {
            throw new AppError('FORBIDDEN', 'Access denied', 403);
        }
        entry.status = 'cancelled';
    }

    /**
     * Trigger scheduled labs that are due. Called by a cron job or timer.
     */
    async triggerDueLabs(): Promise<number> {
        const now = new Date();
        let triggered = 0;

        for (const [id, entry] of scheduledLabs.entries()) {
            if (entry.status === 'pending' && entry.scheduledAt <= now) {
                try {
                    const mockReq = { user: { sub: entry.userId, role: 'student' } };
                    await orchestrator.provisionLab(mockReq, entry.labId);
                    entry.status = 'triggered';
                    triggered++;
                } catch (err: any) {
                    console.error(`Failed to trigger scheduled lab ${id}:`, err.message);
                }
            }
        }

        return triggered;
    }
}

export const schedulerService = new SchedulerService();
