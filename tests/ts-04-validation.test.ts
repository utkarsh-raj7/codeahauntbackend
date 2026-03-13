import { describe, it, expect, vi, beforeEach } from 'vitest';
import { ValidationService } from '../src/services/validation.service';

// Mock dependencies
vi.mock('../src/config/database', () => ({
    db: {
        select: vi.fn().mockReturnValue({
            from: vi.fn().mockReturnValue({
                where: vi.fn().mockResolvedValue([])
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
        execInContainer: vi.fn().mockResolvedValue({ stdout: 'OK', stderr: '', exitCode: 0 }),
    }
}));

vi.mock('../src/utils/publishEvent', () => ({
    publishEvent: vi.fn().mockResolvedValue(undefined),
}));

describe('TS-04: Step Validation (Phase 6)', () => {
    let validationService: ValidationService;

    beforeEach(() => {
        vi.clearAllMocks();
        validationService = new ValidationService();
    });

    it('T45: validateStep should pass when command exits 0', async () => {
        const { db } = await import('../src/config/database');
        (db.select as any) = vi.fn().mockReturnValue({
            from: vi.fn().mockReturnValue({
                where: vi.fn().mockResolvedValue([{
                    id: 's1', status: 'ready', containerId: 'cnt-1'
                }])
            })
        });

        const result = await validationService.validateStep('s1', 'step-1', 'echo ok');
        expect(result.passed).toBe(true);
        expect(result.exitCode).toBe(0);
        expect(result.stepId).toBe('step-1');
    });

    it('T46: validateStep should fail when command exits non-zero', async () => {
        const { containerService } = await import('../src/services/container.service');
        (containerService.execInContainer as any).mockResolvedValue({
            stdout: '', stderr: 'not found', exitCode: 1
        });

        const { db } = await import('../src/config/database');
        (db.select as any) = vi.fn().mockReturnValue({
            from: vi.fn().mockReturnValue({
                where: vi.fn().mockResolvedValue([{
                    id: 's1', status: 'ready', containerId: 'cnt-1'
                }])
            })
        });

        const result = await validationService.validateStep('s1', 'step-2', 'false');
        expect(result.passed).toBe(false);
        expect(result.exitCode).toBe(1);
    });

    it('T47: containerId MUST come from DB session record, not from request', async () => {
        const { db } = await import('../src/config/database');
        const { containerService } = await import('../src/services/container.service');

        (db.select as any) = vi.fn().mockReturnValue({
            from: vi.fn().mockReturnValue({
                where: vi.fn().mockResolvedValue([{
                    id: 's1', status: 'ready', containerId: 'db-container-id'
                }])
            })
        });
        (containerService.execInContainer as any).mockResolvedValue({
            stdout: 'ok', stderr: '', exitCode: 0
        });

        await validationService.validateStep('s1', 'step-1', 'test');

        // Verify execInContainer was called with the DB containerId
        expect(containerService.execInContainer).toHaveBeenCalledWith(
            'db-container-id', // from DB, not from request
            ['sh', '-c', 'test'],
            expect.any(Number)
        );
    });

    it('T48: validateStep should throw SESSION_NOT_FOUND for missing session', async () => {
        const { db } = await import('../src/config/database');
        (db.select as any) = vi.fn().mockReturnValue({
            from: vi.fn().mockReturnValue({
                where: vi.fn().mockResolvedValue([])
            })
        });

        await expect(validationService.validateStep('ghost', 'step-1', 'echo'))
            .rejects.toThrow('Session not found');
    });

    it('T49: validateStep should throw SESSION_NOT_READY for non-ready session', async () => {
        const { db } = await import('../src/config/database');
        (db.select as any) = vi.fn().mockReturnValue({
            from: vi.fn().mockReturnValue({
                where: vi.fn().mockResolvedValue([{
                    id: 's1', status: 'provisioning', containerId: null
                }])
            })
        });

        await expect(validationService.validateStep('s1', 'step-1', 'echo'))
            .rejects.toThrow('Session is not in ready state');
    });

    it('T50: validateStep should throw CONTAINER_NOT_FOUND if containerId is null', async () => {
        const { db } = await import('../src/config/database');
        (db.select as any) = vi.fn().mockReturnValue({
            from: vi.fn().mockReturnValue({
                where: vi.fn().mockResolvedValue([{
                    id: 's1', status: 'ready', containerId: null
                }])
            })
        });

        await expect(validationService.validateStep('s1', 'step-1', 'echo'))
            .rejects.toThrow('No container associated with this session');
    });

    it('T51: validateStep should publish step_validated event', async () => {
        const { db } = await import('../src/config/database');
        const { publishEvent } = await import('../src/utils/publishEvent');

        (db.select as any) = vi.fn().mockReturnValue({
            from: vi.fn().mockReturnValue({
                where: vi.fn().mockResolvedValue([{
                    id: 's1', status: 'ready', containerId: 'cnt-1'
                }])
            })
        });

        await validationService.validateStep('s1', 'step-x', 'echo ok');

        expect(publishEvent).toHaveBeenCalledWith('s1', 'step_validated', expect.objectContaining({
            stepId: 'step-x',
            passed: true,
        }));
    });

    it('T52: validateAllSteps should stop on first failure', async () => {
        const { db } = await import('../src/config/database');
        const { containerService } = await import('../src/services/container.service');

        let callCount = 0;
        (containerService.execInContainer as any).mockImplementation(() => {
            callCount++;
            if (callCount === 2) return { stdout: '', stderr: 'fail', exitCode: 1 };
            return { stdout: 'ok', stderr: '', exitCode: 0 };
        });

        (db.select as any) = vi.fn().mockReturnValue({
            from: vi.fn().mockReturnValue({
                where: vi.fn().mockResolvedValue([{
                    id: 's1', status: 'ready', containerId: 'cnt-1'
                }])
            })
        });

        const steps = [
            { id: 'step-1', validation_cmd: 'cmd1' },
            { id: 'step-2', validation_cmd: 'cmd2' },
            { id: 'step-3', validation_cmd: 'cmd3' },
        ];

        const results = await validationService.validateAllSteps('s1', steps);
        expect(results).toHaveLength(2); // stopped after step-2 failure
        expect(results[0].passed).toBe(true);
        expect(results[1].passed).toBe(false);
    });
});
