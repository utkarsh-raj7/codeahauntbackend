import { pgTable, timestamp, uuid, real, bigserial, index } from 'drizzle-orm/pg-core';
import { sessions } from './sessions';

export const resourceSnapshots = pgTable('resource_snapshots', {
    id: bigserial('id', { mode: 'number' }).primaryKey(),
    sessionId: uuid('session_id').notNull().references(() => sessions.id, { onDelete: 'cascade' }),
    cpuPercent: real('cpu_percent').notNull(),
    memoryMb: real('memory_mb').notNull(),
    recordedAt: timestamp('recorded_at', { withTimezone: true }).notNull().defaultNow()
}, (table) => {
    return {
        sessionRecordedIdx: index('idx_resources_session').on(table.sessionId, table.recordedAt),
    };
});
