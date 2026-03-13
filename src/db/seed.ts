import { db } from '../config/database';
import { labs } from './schema/labs';

async function seed() {
    console.log('Seeding labs...');

    await db.insert(labs).values([
        {
            id: 'k8s-basics-01',
            title: 'Kubernetes Basics 01',
            description: 'Learn the fundamentals of Kubernetes pod creation and deployment.',
            difficulty: 'beginner',
            category: 'kubernetes',
            dockerImage: 'lab-k8s-basics:latest',
            estimatedMinutes: 45,
            ttlSeconds: 3600,
            cpuLimit: 0.5,
            memoryLimitMb: 512,
            exposePort: 7681,
            isActive: true,
            steps: [
                {
                    id: 'step-1',
                    name: 'Create a Pod',
                    validation_cmd: 'kubectl get pod test-pod'
                }
            ],
            resources: [],
            tags: ['k8s', 'beginner']
        },
        {
            id: 'linux-basics-01',
            title: 'Linux Fundamentals',
            description: 'Learn basic Linux navigation and file commands.',
            difficulty: 'beginner',
            category: 'linux',
            dockerImage: 'ubuntu:22.04',
            initScript: 'apt-get update && apt-get install -y vim',
            estimatedMinutes: 30,
            ttlSeconds: 3600,
            cpuLimit: 0.25,
            memoryLimitMb: 256,
            exposePort: 7681,
            isActive: true,
            steps: [
                {
                    id: 'step-1',
                    name: 'Create a file',
                    validation_cmd: 'test -f /tmp/hello.txt'
                }
            ],
            resources: [],
            tags: ['linux', 'fundamentals']
        }
    ]).onConflictDoNothing(); // Prevent duplicates

    console.log('Seeding complete.');
    process.exit(0);
}

seed().catch((err) => {
    console.error('Seed error:', err);
    process.exit(1);
});
