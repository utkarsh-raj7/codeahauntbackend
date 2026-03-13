import { describe, it, expect, vi, beforeEach } from 'vitest';
import { ResourceService } from '../src/services/resource.service';

// Mock dependencies
vi.mock('../src/config/database', () => ({
    db: {
        select: vi.fn().mockImplementation((columns?: any) => ({
            from: vi.fn().mockReturnValue({
                where: vi.fn().mockResolvedValue(
                    columns ? [{ avg_cpu: 45.5, peak_memory_mb: 256 }] : []
                )
            })
        })),
    }
}));

vi.mock('../src/config/redis', () => ({
    redisClient: {
        get: vi.fn().mockResolvedValue(null),
        set: vi.fn().mockResolvedValue('OK'),
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
        getContainerStats: vi.fn().mockResolvedValue({ cpu_percent: 35.2, memory_mb: 128 }),
        listLabContainers: vi.fn().mockResolvedValue([]),
    }
}));

vi.mock('../src/utils/publishEvent', () => ({
    publishEvent: vi.fn().mockResolvedValue(undefined),
}));

// Mock the resources schema so eq() doesn't fail on .sessionId
vi.mock('../src/db/schema/resources', () => ({
    resources: {
        sessionId: 'session_id',
    }
}));

vi.mock('drizzle-orm', async (importOriginal) => {
    const actual = await importOriginal() as any;
    return {
        ...actual,
        eq: vi.fn().mockReturnValue({}),
        sql: actual.sql,
    };
});

describe('TS-05: Resource Monitoring (Phase 6)', () => {
    let resourceService: ResourceService;

    beforeEach(() => {
        vi.clearAllMocks();
        resourceService = new ResourceService();
    });

    it('T55: getLiveStats should return cpu_percent and memory_mb', async () => {
        const result = await resourceService.getLiveStats('s1', 'cnt-1');
        expect(result.cpu_percent).toBe(35.2);
        expect(result.memory_mb).toBe(128);
    });

    it('T56: getLiveStats should throw RESOURCE_ERROR on container failure', async () => {
        const { containerService } = await import('../src/services/container.service');
        (containerService.getContainerStats as any).mockRejectedValueOnce(new Error('container gone'));

        await expect(resourceService.getLiveStats('s1', 'cnt-1'))
            .rejects.toThrow('Failed to fetch live stats');
    });

    it('T57: getAggregatedStats should return avg_cpu and peak_memory_mb', async () => {
        const result = await resourceService.getAggregatedStats('s1');
        expect(result.avg_cpu).toBe(45.5);
        expect(result.peak_memory_mb).toBe(256);
    });

    it('T58: getAggregatedStats should return zeros when no snapshots exist', async () => {
        const { db } = await import('../src/config/database');
        (db.select as any) = vi.fn().mockImplementation(() => ({
            from: vi.fn().mockReturnValue({
                where: vi.fn().mockResolvedValue([{ avg_cpu: null, peak_memory_mb: null }])
            })
        }));

        const result = await resourceService.getAggregatedStats('s1');
        expect(result.avg_cpu).toBe(0);
        expect(result.peak_memory_mb).toBe(0);
    });

    it('T59: checkCapacity should return capacity info', async () => {
        const result = await resourceService.checkCapacity();
        expect(result.active_containers).toBe(0);
        expect(result.max_capacity).toBe(50);
        expect(result.available).toBe(50);
        expect(result.is_at_capacity).toBe(false);
    });

    it('T60: checkCapacity should report at_capacity when full', async () => {
        const { containerService } = await import('../src/services/container.service');
        const mockContainers = Array.from({ length: 50 }, (_, i) => ({ id: `c-${i}` }));
        (containerService.listLabContainers as any).mockResolvedValueOnce(mockContainers);

        const result = await resourceService.checkCapacity();
        expect(result.is_at_capacity).toBe(true);
        expect(result.available).toBe(0);
    });

    it('T61: getLiveStats should call getContainerStats with correct containerId', async () => {
        const { containerService } = await import('../src/services/container.service');
        (containerService.getContainerStats as any).mockResolvedValueOnce({ cpu_percent: 10, memory_mb: 64 });

        await resourceService.getLiveStats('s1', 'specific-container-id');
        expect(containerService.getContainerStats).toHaveBeenCalledWith('specific-container-id');
    });

    it('T62: checkCapacity should use MAX_TOTAL_ACTIVE_CONTAINERS env var', async () => {
        const result = await resourceService.checkCapacity();
        expect(result.max_capacity).toBe(50);
    });
});
