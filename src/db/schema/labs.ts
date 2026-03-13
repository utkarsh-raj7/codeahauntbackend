import { pgTable, text, timestamp, boolean, integer, real, jsonb } from 'drizzle-orm/pg-core';

export const labs = pgTable('labs', {
    id: text('id').primaryKey(),
    title: text('title').notNull(),
    description: text('description'),
    difficulty: text('difficulty').notNull(),
    category: text('category').notNull(),
    dockerImage: text('docker_image').notNull(),
    initScript: text('init_script'),
    estimatedMinutes: integer('estimated_minutes').notNull().default(30),
    ttlSeconds: integer('ttl_seconds').notNull().default(3600),
    cpuLimit: real('cpu_limit').notNull().default(0.5),
    memoryLimitMb: integer('memory_limit_mb').notNull().default(512),
    exposePort: integer('expose_port').notNull().default(7681),
    tags: text('tags').array().default([]),
    steps: jsonb('steps').notNull().default([]),
    resources: jsonb('resources').notNull().default([]),
    isActive: boolean('is_active').notNull().default(true),
    createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow()
});
