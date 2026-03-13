import { pgTable, text, timestamp, uuid, integer, boolean, unique, index } from 'drizzle-orm/pg-core';
import { sessions } from './sessions';

export const stepProgress = pgTable('step_progress', {
    id: uuid('id').defaultRandom().primaryKey(),
    sessionId: uuid('session_id').notNull().references(() => sessions.id, { onDelete: 'cascade' }),
    stepId: text('step_id').notNull(),
    status: text('status').notNull().default('pending'),
    validatedAt: timestamp('validated_at', { withTimezone: true }),
    attempts: integer('attempts').notNull().default(0),
    hintShown: boolean('hint_shown').notNull().default(false)
}, (table) => {
    return {
        uniqueSessionStep: unique().on(table.sessionId, table.stepId),
        sessionIdx: index('idx_step_progress_session').on(table.sessionId)
    };
});
