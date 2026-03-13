import Redis from 'ioredis';

const REDIS_URL = process.env.REDIS_URL || 'redis://localhost:6379';

// For commands (GET, SET, etc)
export const redisClient = new Redis(REDIS_URL);

// For subscribing to pub/sub channels and keyspace events
export const redisSub = new Redis(REDIS_URL);

// Configure keyspace expiry events listening
redisSub.subscribe('__keyevent@0__:expired', (err, count) => {
    if (err) {
        console.error('Failed to subscribe to expiry events:', err);
    } else {
        console.log(`Subscribed to keyspace expiry events (count: ${count})`);
    }
});

redisSub.on('message', (channel, message) => {
    if (channel === '__keyevent@0__:expired') {
        // Expected to enqueue BullMQ cleanup job here in later phases
        console.log(`Key expired: ${message}`);
    }
});
