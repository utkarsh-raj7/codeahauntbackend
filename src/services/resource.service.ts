import { containerService } from './container.service';
import { db } from '../config/database';
import { resourceSnapshots } from '../db/schema/resources';
import { eq, sql } from 'drizzle-orm';
import { AppError } from '../types';

export class ResourceService {
    async getLiveStats(sessionId: string, containerId: string) {
        try {
            const stats = await containerService.getContainerStats(containerId);
            return {
                cpu_percent: stats.cpu_percent,
                memory_mb: stats.memory_mb
            };
        } catch (err: any) {
            throw new AppError('RESOURCE_ERROR', `Failed to fetch live stats: ${err.message}`, 500);
        }
    }

    async getAggregatedStats(sessionId: string) {
        // Query resource_snapshots for min/max/avg
        const result = await db
            .select({
                avg_cpu: sql<number>`avg(cpu_percent)::numeric(5,2)`,
                peak_memory_mb: sql<number>`max(memory_mb)::numeric(10,2)`
            })
            .from(resourceSnapshots)
            .where(eq(resourceSnapshots.sessionId, sessionId));

        if (!result.length || result[0].avg_cpu === null) {
            return { avg_cpu: 0, peak_memory_mb: 0 };
        }

        return result[0];
    }

    async checkCapacity() {
        const containers = await containerService.listLabContainers();
        const MAX_TOTAL = parseInt(process.env.MAX_TOTAL_ACTIVE_CONTAINERS || '50', 10);

        return {
            active_containers: containers.length,
            max_capacity: MAX_TOTAL,
            available: MAX_TOTAL - containers.length,
            is_at_capacity: containers.length >= MAX_TOTAL
        };
    }
}

export const resourceService = new ResourceService();
