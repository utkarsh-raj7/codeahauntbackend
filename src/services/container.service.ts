import Docker from 'dockerode';
import { AppError } from '../types';

const docker = new Docker({ socketPath: process.env.DOCKER_SOCKET || '/var/run/docker.sock' });

export interface ContainerConfig {
    sessionId: string;
    userId: string;
    image: string;
    exposePort?: number;
}

export class ContainerService {
    async createContainer(config: ContainerConfig) {
        try {
            // Pull image if not cached. 
            // In a real scenario we'd check if it exists first, but docker pull handles it cleanly if available.
            try {
                const stream = await docker.pull(config.image);
                await new Promise((resolve, reject) => {
                    docker.modem.followProgress(stream, (err, res) => err ? reject(err) : resolve(res));
                });
            } catch (err) {
                console.warn(`Could not pull image ${config.image}, attempting to use local cache...`);
            }

            const cpuLimit = parseFloat(process.env.CONTAINER_CPU_LIMIT || '0.5') * 1e9;
            const memoryLimit = parseInt(process.env.CONTAINER_MEMORY_LIMIT || '536870912', 10);
            const networkMode = process.env.CONTAINER_NETWORK || 'lab-network';
            const baseDomain = process.env.BASE_DOMAIN || 'labs.yourdomain.com';
            const exposePort = config.exposePort || 7681;

            const container = await docker.createContainer({
                Image: config.image,
                name: `lab-${config.sessionId}`,
                HostConfig: {
                    NanoCPUs: cpuLimit,
                    Memory: memoryLimit,
                    NetworkMode: networkMode,
                    SecurityOpt: ['no-new-privileges:true'],
                },
                Labels: {
                    'com.labsystem': 'true',
                    'com.session_id': config.sessionId,
                    'com.user_id': config.userId,

                    // Phase 2.2: Traefik Label Injection
                    'traefik.enable': 'true',
                    [`traefik.http.routers.${config.sessionId}.rule`]: `Host(\`${config.sessionId}.${baseDomain}\`)`,
                    [`traefik.http.routers.${config.sessionId}.entrypoints`]: 'web',
                    [`traefik.http.services.${config.sessionId}.loadbalancer.server.port`]: `${exposePort}`
                }
            });

            return container.id;
        } catch (err: any) {
            throw new AppError('CONTAINER_ERROR', `Failed to create container: ${err.message}`, 500);
        }
    }

    async startContainer(id: string) {
        try {
            const container = docker.getContainer(id);
            await container.start();
            return id;
        } catch (err: any) {
            throw new AppError('CONTAINER_ERROR', `Failed to start container: ${err.message}`, 500);
        }
    }

    async stopContainer(id: string) {
        try {
            const container = docker.getContainer(id);
            await container.stop({ t: 10 }); // SIGTERM -> wait 10s -> SIGKILL
        } catch (err: any) {
            // gracefully handle container not found or already stopped
            if (err.statusCode === 304 || err.statusCode === 404) return;
            throw new AppError('CONTAINER_ERROR', `Failed to stop container: ${err.message}`, 500);
        }
    }

    async removeContainer(id: string) {
        try {
            const container = docker.getContainer(id);
            await container.remove({ force: true });
        } catch (err: any) {
            if (err.statusCode === 404) return;
            throw new AppError('CONTAINER_ERROR', `Failed to remove container: ${err.message}`, 500);
        }
    }

    async inspectContainer(id: string) {
        try {
            const container = docker.getContainer(id);
            const data = await container.inspect();
            return {
                running: data.State.Running,
                ip: Object.values(data.NetworkSettings?.Networks || {})[0]?.IPAddress || '',
                exitCode: data.State.ExitCode
            };
        } catch (err: any) {
            throw new AppError('CONTAINER_ERROR', `Failed to inspect container: ${err.message}`, 500);
        }
    }

    async getContainerStats(id: string) {
        try {
            const container = docker.getContainer(id);
            const stats = await container.stats({ stream: false });

            // Calculate CPU percent
            const cpuDelta = stats.cpu_stats.cpu_usage.total_usage - stats.precpu_stats.cpu_usage.total_usage;
            const systemDelta = stats.cpu_stats.system_cpu_usage - stats.precpu_stats.system_cpu_usage;
            let cpu_percent = 0;
            if (systemDelta > 0 && cpuDelta > 0) {
                cpu_percent = (cpuDelta / systemDelta) * (stats.cpu_stats.online_cpus || 1) * 100.0;
            }

            const memory_mb = stats.memory_stats.usage / (1024 * 1024);

            return { cpu_percent, memory_mb };
        } catch (err: any) {
            throw new AppError('CONTAINER_ERROR', `Failed to get container stats: ${err.message}`, 500);
        }
    }

    async execInContainer(id: string, cmd: string[], timeoutMs: number = 10000) {
        try {
            const container = docker.getContainer(id);
            const exec = await container.exec({
                Cmd: cmd,
                AttachStdout: true,
                AttachStderr: true
            });

            const stream = await exec.start({ Detach: false });

            return await new Promise<{ stdout: string, stderr: string, exitCode: number }>((resolve, reject) => {
                let stdout = '';
                let stderr = '';

                // Docker stream is multiplexed, docker-modem can demux
                docker.modem.demuxStream(stream, {
                    write: (chunk: Buffer) => { stdout += chunk.toString('utf8'); }
                }, {
                    write: (chunk: Buffer) => { stderr += chunk.toString('utf8'); }
                });

                const timeout = setTimeout(() => {
                    resolve({ stdout, stderr, exitCode: 124 }); // timeout code
                }, timeoutMs);

                stream.on('end', async () => {
                    clearTimeout(timeout);
                    const data = await exec.inspect();
                    resolve({ stdout, stderr, exitCode: data.ExitCode || 0 });
                });

                stream.on('error', (err) => {
                    clearTimeout(timeout);
                    reject(err);
                });
            });
        } catch (err: any) {
            throw new AppError('CONTAINER_ERROR', `Failed to exec in container: ${err.message}`, 500);
        }
    }

    async listLabContainers() {
        try {
            const containers = await docker.listContainers({
                all: true,
                filters: { 'label': ['com.labsystem=true'] }
            });
            return containers;
        } catch (err: any) {
            throw new AppError('CONTAINER_ERROR', `Failed to list lab containers: ${err.message}`, 500);
        }
    }
}

export const containerService = new ContainerService();
