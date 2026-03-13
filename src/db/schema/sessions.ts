import { pgTable, text, timestamp, uuid, integer, index } from 'drizzle-orm/pg-core';
import { users } from './users';
import { labs } from './labs';

export const sessions = pgTable('sessions', {
    id: uuid('id').defaultRandom().primaryKey(),
    userId: uuid('user_id').notNull().references(() => users.id, { onDelete: 'cascade' }),
    labId: text('lab_id').notNull().references(() => labs.id),
    status: text('status').notNull().default('provisioning'),
    containerId: text('container_id'),
    subdomain: text('subdomain').unique(),
    terminalUrl: text('terminal_url'),
    errorMessage: text('error_message'),
    ttlSeconds: integer('ttl_seconds').notNull(),
    createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
    readyAt: timestamp('ready_at', { withTimezone: true }),
    expiresAt: timestamp('expires_at', { withTimezone: true }).notNull(),
    endedAt: timestamp('ended_at', { withTimezone: true })
}, (table) => {
    return {
        userIdIdx: index('idx_sessions_user_id').on(table.userId),
        statusIdx: index('idx_sessions_status').on(table.status),
        expiresAtIdx: index('idx_sessions_expires_at').on(table.expiresAt),
        subdomainIdx: index('idx_sessions_subdomain').on(table.subdomain),
    };
});
