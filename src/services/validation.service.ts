import { db } from '../config/database';
import { sessions } from '../db/schema/sessions';
import { eq } from 'drizzle-orm';
import { containerService } from './container.service';
import { AppError } from '../types';
import { publishEvent } from '../utils/publishEvent';

export interface ValidationResult {
    stepId: string;
    passed: boolean;
    output: string;
    exitCode: number;
}

export class ValidationService {
    /**
     * Validate a lab step by executing the validation command inside the session's container.
     * CRITICAL: container_id MUST come from the DB session record, NEVER from the request body.
     */
    async validateStep(sessionId: string, stepId: string, validationCmd: string): Promise<ValidationResult> {
        // 1. Look up session from DB to get container_id
        const sessionRecord = await db.select().from(sessions).where(eq(sessions.id, sessionId));
        if (!sessionRecord || sessionRecord.length === 0) {
            throw new AppError('SESSION_NOT_FOUND', 'Session not found', 404);
        }

        const session = sessionRecord[0];

        if (session.status !== 'ready') {
            throw new AppError('SESSION_NOT_READY', 'Session is not in ready state', 400);
        }

        // container_id is always from DB, never from request
        const containerId = session.containerId;
        if (!containerId) {
            throw new AppError('CONTAINER_NOT_FOUND', 'No container associated with this session', 500);
        }

        // 2. Execute the validation command inside the container
        const VALIDATION_TIMEOUT = parseInt(process.env.VALIDATION_TIMEOUT_MS || '10000', 10);

        try {
            const result = await containerService.execInContainer(
                containerId,
                ['sh', '-c', validationCmd],
                VALIDATION_TIMEOUT
            );

            const passed = result.exitCode === 0;

            // 3. Publish validation event over WebSocket
            await publishEvent(sessionId, 'step_validated', {
                stepId,
                passed,
                output: result.stdout || result.stderr,
                exitCode: result.exitCode,
            });

            return {
                stepId,
                passed,
                output: result.stdout || result.stderr,
                exitCode: result.exitCode,
            };
        } catch (err: any) {
            // If exec itself fails (container gone, timeout, etc.)
            if (err instanceof AppError) throw err;
            throw new AppError('VALIDATION_ERROR', `Validation failed: ${err.message}`, 500);
        }
    }

    /**
     * Validate all steps sequentially for a given session.
     */
    async validateAllSteps(
        sessionId: string,
        steps: Array<{ id: string; validation_cmd: string }>
    ): Promise<ValidationResult[]> {
        const results: ValidationResult[] = [];

        for (const step of steps) {
            const result = await this.validateStep(sessionId, step.id, step.validation_cmd);
            results.push(result);
            // Stop on first failure
            if (!result.passed) break;
        }

        return results;
    }
}

export const validationService = new ValidationService();
