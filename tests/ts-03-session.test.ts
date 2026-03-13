import { describe, it, expect, vi, beforeEach } from 'vitest';
import { SessionService } from '../src/services/session.service';

// Mock dependencies
vi.mock('../src/config/database', () => ({
    db: {
        select: vi.fn().mockReturnValue({
            from: vi.fn().mockReturnValue({
                where: vi.fn().mockResolvedValue([])
            })
        }),
        update: vi.fn().mockReturnValue({
            set: vi.fn().mockReturnValue({
                where: vi.fn().mockResolvedValue(undefined)
            })
        }),
    }
}));

vi.mock('../src/config/redis', () => ({
    redisClient: {
        get: vi.fn().mockResolvedValue(null),
        set: vi.fn().mockResolvedValue('OK'),
        del: vi.fn().mockResolvedValue(1),
        ttl: vi.fn().mockResolvedValue(3600),
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

vi.mock('../src/utils/publishEvent', () => ({
    publishEvent: vi.fn().mockResolvedValue(undefined),
}));

describe('TS-03: Session Lifecycle & TTL (Phase 6)', () => {
    let sessionService: SessionService;

    beforeEach(() => {
        vi.clearAllMocks();
        sessionService = new SessionService();
    });

    it('T31: heartbeat should reset Redis TTL to DEFAULT_SESSION_TTL', async () => {
        const { db } = await import('../src/config/database');
        const { redisClient } = await import('../src/config/redis');
        (db.select as any) = vi.fn().mockReturnValue({
            from: vi.fn().mockReturnValue({
                where: vi.fn().mockResolvedValue([{ id: 's1', userId: 'u1', status: 'ready' }])
            })
        });

        const result = await sessionService.heartbeat('s1', 'u1');
        expect(result.time_remaining_seconds).toBe(3600);
        expect(redisClient.set).toHaveBeenCalledWith('sess:s1', '1', 'EX', 3600);
    });

    it('T32: heartbeat should throw SESSION_NOT_FOUND for missing session', async () => {
        const { db } = await import('../src/config/database');
        (db.select as any) = vi.fn().mockReturnValue({
            from: vi.fn().mockReturnValue({
                where: vi.fn().mockResolvedValue([])
            })
        });

        await expect(sessionService.heartbeat('ghost', 'u1'))
            .rejects.toThrow('Session not found');
    });

    it('T33: extendSession should increase expiresAt within MAX_SESSION_TTL', async () => {
        const now = new Date();
        const { db } = await import('../src/config/database');
        (db.select as any) = vi.fn().mockReturnValue({
            from: vi.fn().mockReturnValue({
                where: vi.fn().mockResolvedValue([{
                    id: 's1', userId: 'u1', status: 'ready',
                    createdAt: now,
                    expiresAt: new Date(now.getTime() + 3600 * 1000),
                }])
            })
        });

        const result = await sessionService.extendSession('s1', 1800, 'u1');
        expect(result.status).toBe('extended');
        expect(result.time_remaining_seconds).toBeGreaterThan(0);
    });

    it('T34: extendSession should throw MAX_TTL_EXCEEDED if over absolute max', async () => {
        const now = new Date();
        const { db } = await import('../src/config/database');
        (db.select as any) = vi.fn().mockReturnValue({
            from: vi.fn().mockReturnValue({
                where: vi.fn().mockResolvedValue([{
                    id: 's1', userId: 'u1', status: 'ready',
                    createdAt: now,
                    expiresAt: new Date(now.getTime() + 14000 * 1000), // near max
                }])
            })
        });

        await expect(sessionService.extendSession('s1', 3600, 'u1'))
            .rejects.toThrow('Cannot extend beyond max TTL');
    });

    it('T35: extendSession should throw SESSION_NOT_FOUND for missing session', async () => {
        const { db } = await import('../src/config/database');
        (db.select as any) = vi.fn().mockReturnValue({
            from: vi.fn().mockReturnValue({
                where: vi.fn().mockResolvedValue([])
            })
        });

        await expect(sessionService.extendSession('ghost', 1800, 'u1'))
            .rejects.toThrow('Session not found');
    });

    it('T36: heartbeat without userId should still work (middleware-based auth)', async () => {
        const { db } = await import('../src/config/database');
        (db.select as any) = vi.fn().mockReturnValue({
            from: vi.fn().mockReturnValue({
                where: vi.fn().mockResolvedValue([{ id: 's1', userId: 'u1', status: 'ready' }])
            })
        });

        const result = await sessionService.heartbeat('s1');
        expect(result.time_remaining_seconds).toBe(3600);
    });

    it('T37: multiple rapid heartbeats should each reset TTL (not stack)', async () => {
        const { db } = await import('../src/config/database');
        const { redisClient } = await import('../src/config/redis');
        (db.select as any) = vi.fn().mockReturnValue({
            from: vi.fn().mockReturnValue({
                where: vi.fn().mockResolvedValue([{ id: 's1', userId: 'u1', status: 'ready' }])
            })
        });

        await sessionService.heartbeat('s1', 'u1');
        await sessionService.heartbeat('s1', 'u1');
        await sessionService.heartbeat('s1', 'u1');

        // Each call sets the same TTL, not cumulative
        expect(redisClient.set).toHaveBeenCalledTimes(3);
        for (const call of (redisClient.set as any).mock.calls) {
            expect(call[3]).toBe(3600);
        }
    });
});
