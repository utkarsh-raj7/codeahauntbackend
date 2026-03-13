import { describe, it, expect, vi, beforeEach } from 'vitest';
import { OrchestratorService } from '../src/services/orchestrator.service';
import { SessionService } from '../src/services/session.service';

// Mock dependencies
vi.mock('../src/config/database', () => ({
    db: {
        select: vi.fn().mockReturnValue({
            from: vi.fn().mockReturnValue({
                where: vi.fn().mockResolvedValue([])
            })
        }),
        insert: vi.fn().mockReturnValue({
            values: vi.fn().mockResolvedValue(undefined)
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
        stopContainer: vi.fn().mockResolvedValue(undefined),
        removeContainer: vi.fn().mockResolvedValue(undefined),
    }
}));

vi.mock('../src/utils/publishEvent', () => ({
    publishEvent: vi.fn().mockResolvedValue(undefined),
}));

vi.mock('bullmq', () => {
    return {
        Queue: class MockQueue {
            add = vi.fn().mockResolvedValue({ id: 'mock-job-id' });
        },
    };
});

describe('TS-02: Provision & Session Lifecycle (Phase 2+5)', () => {
    let orchestrator: OrchestratorService;
    let sessionService: SessionService;

    beforeEach(() => {
        vi.clearAllMocks();
        orchestrator = new OrchestratorService();
        sessionService = new SessionService();
    });

    it('T01: provisionLab should create a session record and enqueue a job', async () => {
        const mockReq = { user: { sub: 'user-123', role: 'student' } };
        const result = await orchestrator.provisionLab(mockReq, 'k8s-basics-01');
        expect(result).toBeDefined();
        expect(result.userId).toBe('user-123');
        expect(result.labId).toBe('k8s-basics-01');
        expect(result.status).toBe('provisioning');
        expect(result.id).toBeDefined();
    });

    it('T02: provisionLab should throw QUOTA_EXCEEDED when user has max sessions', async () => {
        const { db } = await import('../src/config/database');
        const selectMock = vi.fn().mockReturnValue({
            from: vi.fn().mockReturnValue({
                where: vi.fn().mockResolvedValue([
                    { id: 's1', status: 'ready' },
                    { id: 's2', status: 'ready' },
                ])
            })
        });
        (db.select as any) = selectMock;

        const mockReq = { user: { sub: 'user-quota', role: 'student' } };
        await expect(orchestrator.provisionLab(mockReq, 'lab-1')).rejects.toThrow('Max 2 sessions allowed');
    });

    it('T03: provisionLab should return existing session for idempotency', async () => {
        const existingSession = { id: 'existing-1', userId: 'user-idem', labId: 'lab-1', status: 'ready' };
        const { db } = await import('../src/config/database');

        let callCount = 0;
        const selectMock = vi.fn().mockReturnValue({
            from: vi.fn().mockReturnValue({
                where: vi.fn().mockImplementation(() => {
                    callCount++;
                    if (callCount === 1) return Promise.resolve([]); // quota check
                    return Promise.resolve([existingSession]); // idempotency check
                })
            })
        });
        (db.select as any) = selectMock;

        const mockReq = { user: { sub: 'user-idem', role: 'student' } };
        const result = await orchestrator.provisionLab(mockReq, 'lab-1');
        expect(result).toEqual(existingSession);
    });

    it('T04: destroyLab should mark session as destroyed and clean up Redis', async () => {
        const session = { id: 'sess-destroy', userId: 'u1', status: 'ready', containerId: null };
        const { db } = await import('../src/config/database');
        const selectMock = vi.fn().mockReturnValue({
            from: vi.fn().mockReturnValue({
                where: vi.fn().mockResolvedValue([session])
            })
        });
        (db.select as any) = selectMock;

        const result = await orchestrator.destroyLab('sess-destroy');
        expect(result.status).toBe('destroyed');
    });

    it('T05: destroyLab should throw SESSION_NOT_FOUND for missing session', async () => {
        const { db } = await import('../src/config/database');
        const selectMock = vi.fn().mockReturnValue({
            from: vi.fn().mockReturnValue({
                where: vi.fn().mockResolvedValue([])
            })
        });
        (db.select as any) = selectMock;

        await expect(orchestrator.destroyLab('nonexistent')).rejects.toThrow('Session not found');
    });

    it('T06: heartbeat should reset TTL and return time_remaining_seconds', async () => {
        const session = { id: 'sess-hb', userId: 'u1', status: 'ready' };
        const { db } = await import('../src/config/database');
        const selectMock = vi.fn().mockReturnValue({
            from: vi.fn().mockReturnValue({
                where: vi.fn().mockResolvedValue([session])
            })
        });
        (db.select as any) = selectMock;

        const result = await sessionService.heartbeat('sess-hb', 'u1');
        expect(result.time_remaining_seconds).toBe(3600);
    });

    it('T07: getSessionStatus should return status and terminal_url', async () => {
        const session = { id: 'sess-st', userId: 'u1', status: 'ready', terminalUrl: 'https://term.example.com' };
        const { db } = await import('../src/config/database');
        const selectMock = vi.fn().mockReturnValue({
            from: vi.fn().mockReturnValue({
                where: vi.fn().mockResolvedValue([session])
            })
        });
        (db.select as any) = selectMock;

        const result = await orchestrator.getSessionStatus('sess-st', 'u1');
        expect(result.status).toBe('ready');
        expect(result.terminal_url).toBe('https://term.example.com');
    });

    it('T08: getSessionStatus should throw FORBIDDEN for wrong user', async () => {
        const session = { id: 'sess-f', userId: 'u1', status: 'ready', terminalUrl: null };
        const { db } = await import('../src/config/database');
        const selectMock = vi.fn().mockReturnValue({
            from: vi.fn().mockReturnValue({
                where: vi.fn().mockResolvedValue([session])
            })
        });
        (db.select as any) = selectMock;

        await expect(orchestrator.getSessionStatus('sess-f', 'wrong-user')).rejects.toThrow('Access denied');
    });
});
