import { pgTable, text, timestamp, uuid, integer, index } from 'drizzle-orm/pg-core';
import { users } from './users';
import { labs } from './labs';
import { sessions } from './sessions';

export const bookings = pgTable('bookings', {
    id: uuid('id').defaultRandom().primaryKey(),
    userId: uuid('user_id').notNull().references(() => users.id, { onDelete: 'cascade' }),
    labId: text('lab_id').notNull().references(() => labs.id),
    slotStart: timestamp('slot_start', { withTimezone: true }).notNull(),
    slotEnd: timestamp('slot_end', { withTimezone: true }).notNull(),
    status: text('status').notNull().default('confirmed'),
    sessionId: uuid('session_id').references(() => sessions.id),
    queuePos: integer('queue_pos'),
    createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
    notifiedAt: timestamp('notified_at', { withTimezone: true })
}, (table) => {
    return {
        userIdx: index('idx_bookings_user').on(table.userId),
        slotIdx: index('idx_bookings_slot').on(table.labId, table.slotStart, table.slotEnd),
    };
});
