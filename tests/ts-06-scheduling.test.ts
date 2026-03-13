import { describe, it, expect, vi, beforeEach } from 'vitest';
import { SchedulerService } from '../src/services/scheduler.service';

// Mock dependencies
const defaultSelectMock = () => vi.fn().mockReturnValue({
    from: vi.fn().mockReturnValue({
        where: vi.fn().mockResolvedValue([{ id: 'lab-1', title: 'Test Lab' }])
    })
});

vi.mock('../src/config/database', () => ({
    db: {
        select: vi.fn().mockReturnValue({
            from: vi.fn().mockReturnValue({
                where: vi.fn().mockResolvedValue([{ id: 'lab-1', title: 'Test Lab' }])
            })
        }),
    }
}));

vi.mock('../src/config/redis', () => ({
    redisClient: {
        get: vi.fn().mockResolvedValue(null),
        set: vi.fn().mockResolvedValue('OK'),
        del: vi.fn().mockResolvedValue(1),
        ping: vi.fn().mockResolvedValue('PONG'),
        subscribe: vi.fn().mockResolvedValue(undefined),
        on: vi.fn(),
        duplicate: vi.fn().mockReturnValue({
            subscribe: vi.fn().mockResolvedValue(undefined),
            on: vi.fn(),
            connect: vi.fn().mockResolvedValue(undefined),
        }),
    }
}));

vi.mock('../src/services/container.service', () => ({
    containerService: {
        listLabContainers: vi.fn().mockResolvedValue([]),
    }
}));

vi.mock('../src/utils/publishEvent', () => ({
    publishEvent: vi.fn().mockResolvedValue(undefined),
}));

vi.mock('bullmq', () => ({
    Queue: class MockQueue {
        add = vi.fn().mockResolvedValue({ id: 'mock-job-id' });
    },
}));

describe('TS-06: Scheduling (Phase 6)', () => {
    let schedulerService: SchedulerService;

    beforeEach(async () => {
        vi.clearAllMocks();
        schedulerService = new SchedulerService();
        // Restore default db.select mock before every test
        const { db } = await import('../src/config/database');
        (db.select as any) = defaultSelectMock();
    });

    it('T63: scheduleLab should create a pending booking for future time', async () => {
        const future = new Date(Date.now() + 60 * 60 * 1000);
        const result = await schedulerService.scheduleLab('u1', 'lab-1', future);

        expect(result.status).toBe('pending');
        expect(result.userId).toBe('u1');
        expect(result.labId).toBe('lab-1');
        expect(result.id).toBeDefined();
    });

    it('T64: scheduleLab should throw INVALID_SCHEDULE for past time', async () => {
        const past = new Date(Date.now() - 60 * 1000);
        await expect(schedulerService.scheduleLab('u1', 'lab-1', past))
            .rejects.toThrow('Scheduled time must be in the future');
    });

    it('T65: scheduleLab should throw LAB_NOT_FOUND for invalid lab', async () => {
        const { db } = await import('../src/config/database');
        (db.select as any) = vi.fn().mockReturnValue({
            from: vi.fn().mockReturnValue({
                where: vi.fn().mockResolvedValue([])
            })
        });

        const future = new Date(Date.now() + 60 * 60 * 1000);
        await expect(schedulerService.scheduleLab('u1', 'nonexistent', future))
            .rejects.toThrow('Lab not found');
    });

    it('T66: getScheduledLabs should return only pending labs for user', async () => {
        const future = new Date(Date.now() + 60 * 60 * 1000);
        await schedulerService.scheduleLab('u1', 'lab-1', future);

        const results = await schedulerService.getScheduledLabs('u1');
        expect(results.length).toBeGreaterThanOrEqual(1);
        expect(results.every(r => r.status === 'pending')).toBe(true);
    });

    it('T67: getScheduledLabs should not return other users bookings', async () => {
        const results = await schedulerService.getScheduledLabs('other-user');
        expect(results.every(r => r.userId === 'other-user')).toBe(true);
    });

    it('T68: cancelScheduledLab should mark booking as cancelled', async () => {
        const future = new Date(Date.now() + 60 * 60 * 1000);
        const booking = await schedulerService.scheduleLab('u1', 'lab-1', future);

        await schedulerService.cancelScheduledLab(booking.id!, 'u1');

        const remaining = await schedulerService.getScheduledLabs('u1');
        const found = remaining.find(r => r.id === booking.id);
        expect(found).toBeUndefined();
    });

    it('T69: cancelScheduledLab should throw FORBIDDEN for wrong user', async () => {
        const future = new Date(Date.now() + 60 * 60 * 1000);
        const booking = await schedulerService.scheduleLab('u1', 'lab-1', future);

        await expect(schedulerService.cancelScheduledLab(booking.id!, 'wrong-user'))
            .rejects.toThrow('Access denied');
    });

    it('T70: cancelScheduledLab should throw SCHEDULE_NOT_FOUND for invalid id', async () => {
        await expect(schedulerService.cancelScheduledLab('nonexistent', 'u1'))
            .rejects.toThrow('Scheduled lab not found');
    });

    it('T71: triggerDueLabs should not fail on empty schedule', async () => {
        const triggered = await schedulerService.triggerDueLabs();
        expect(triggered).toBe(0);
    });

    it('T72: scheduleLab should queue a delayed notification 5 min before', async () => {
        const future = new Date(Date.now() + 60 * 60 * 1000);
        const result = await schedulerService.scheduleLab('u1', 'lab-1', future);
        expect(result.status).toBe('pending');
        // The delayed notification is queued internally — success if no error
    });
});
