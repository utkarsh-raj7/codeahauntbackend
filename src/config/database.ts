import { drizzle } from 'drizzle-orm/node-postgres';
import pg from 'pg';

const { Pool } = pg;

const pool = new Pool({
    connectionString: process.env.DATABASE_URL || 'postgresql://labuser:devpassword@localhost:5432/labdb'
});

export const db = drizzle(pool);
