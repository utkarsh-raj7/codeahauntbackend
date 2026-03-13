import { FastifyInstance, FastifyError } from 'fastify';
import { AppError } from '../types';
import { ZodError } from 'zod';

export function setupErrorHandler(app: FastifyInstance) {
    app.setErrorHandler(function (error: FastifyError | Error | any, request, reply) {
        // Validation Errors (Fastify / Zod)
        if (error.validation || error instanceof ZodError) {
            return reply.status(400).send({
                error: {
                    code: 'VALIDATION_ERROR',
                    message: 'Invalid request data',
                    // eslint-disable-next-line @typescript-eslint/no-unsafe-assignment
                    details: error.validation || error.errors || error.issues,
                    http_status: 400
                }
            });
        }

        // Custom App Errors or generic HTTP Errors
        const status = error.http_status || error.statusCode;
        if (status && status !== 500 && status !== 429) {
            return reply.status(status).send({
                error: {
                    code: error.code || 'ERROR',
                    message: error.message,
                    http_status: status
                }
            });
        }

        // Fastify Built-ins (e.g. rate limit)
        if (status === 429) {
            return reply.status(429).send({
                error: {
                    code: 'RATE_LIMIT_EXCEEDED',
                    message: 'Too many requests, please try again later.',
                    http_status: 429
                }
            });
        }

        // Fallback Unhandled Errors
        app.log.error(error);

        const isProd = process.env.NODE_ENV === 'production';
        return reply.status(500).send({
            error: {
                code: 'INTERNAL_ERROR',
                message: isProd ? 'An unexpected error occurred' : error.message,
                http_status: 500
                // Never expose stack trace when NODE_ENV === 'production'
            }
        });
    });
}
