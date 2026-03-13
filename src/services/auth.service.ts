import bcrypt from 'bcrypt';
import * as jwt from 'jsonwebtoken';
import { randomUUID } from 'crypto';
import { redisClient } from '../config/redis';
import { AppError } from '../types';

export class AuthService {
    private readonly JWT_SECRET = process.env.JWT_SECRET || 'your-256-bit-secret-here';
    private readonly JWT_EMBED_SECRET = process.env.JWT_EMBED_SECRET || 'your-embed-secret-here';
    private readonly ACCESS_EXPIRES = parseInt(process.env.JWT_ACCESS_EXPIRES || '900', 10);
    private readonly REFRESH_EXPIRES = parseInt(process.env.JWT_REFRESH_EXPIRES || '604800', 10);
    private readonly EMBED_EXPIRES = parseInt(process.env.LAB_TOKEN_EXPIRES || '600', 10);

    async hashPassword(plain: string): Promise<string> {
        return bcrypt.hash(plain, 12);
    }

    async verifyPassword(plain: string, hash: string): Promise<boolean> {
        return bcrypt.compare(plain, hash);
    }

    async issueAccessToken(userId: string, role: string): Promise<string> {
        return jwt.sign(
            { sub: userId, role, type: 'access' },
            this.JWT_SECRET,
            { expiresIn: this.ACCESS_EXPIRES }
        );
    }

    async issueRefreshToken(userId: string): Promise<string> {
        const family = randomUUID();
        const token = jwt.sign(
            { sub: userId, family, type: 'refresh' },
            this.JWT_SECRET,
            { expiresIn: this.REFRESH_EXPIRES }
        );

        await redisClient.set(
            `refresh:${userId}:${family}`,
            '1',
            'EX',
            this.REFRESH_EXPIRES
        );

        return token;
    }

    async issueEmbedToken(sessionId: string, userId: string): Promise<string> {
        return jwt.sign(
            { sub: userId, session_id: sessionId, scope: 'embed', type: 'embed' },
            this.JWT_EMBED_SECRET,
            { expiresIn: this.EMBED_EXPIRES }
        );
    }

    async verifyToken(token: string, secretType: 'access' | 'embed' = 'access'): Promise<jwt.JwtPayload> {
        const secret = secretType === 'embed' ? this.JWT_EMBED_SECRET : this.JWT_SECRET;
        try {
            return jwt.verify(token, secret) as jwt.JwtPayload;
        } catch (err: unknown) {
            if (err instanceof Error && err.name === 'TokenExpiredError') {
                throw new AppError('TOKEN_EXPIRED', 'Token has expired', 401);
            }
            throw new AppError('UNAUTHORIZED', 'Invalid token', 401);
        }
    }

    async refreshTokens(refreshToken: string): Promise<{ accessToken: string; newRefreshToken: string }> {
        let decoded: jwt.JwtPayload;
        try {
            decoded = await this.verifyToken(refreshToken);
        } catch (err: unknown) {
            throw err;
        }

        if (decoded.type !== 'refresh') {
            throw new AppError('UNAUTHORIZED', 'Invalid token type', 401);
        }

        const userId = decoded.sub as string;
        const family = decoded.family as string;

        const redisKey = `refresh:${userId}:${family}`;
        const isValid = await redisClient.get(redisKey);

        if (!isValid) {
            // Replay attack detected or family manually revoked. Revoke ALL tokens.
            await this.revokeAllUserTokens(userId);
            throw new AppError('UNAUTHORIZED', 'Token family revoked or invalid', 401);
        }

        // Invalidate old family token, issue new pair
        await redisClient.del(redisKey);

        // Normally we'd fetch the user role from DB here, assuming 'student' for mock example
        // We'll let the router pass the role, or assume fallback if needed.
        // For standard internal refresh logic, role is usually embedded or looked up.
        // Assume lookup will occur externally or defaults to string here if we just pipe it.
        const accessToken = await this.issueAccessToken(userId, decoded.role || 'student');
        const newRefreshToken = await this.issueRefreshToken(userId);

        return { accessToken, newRefreshToken };
    }

    async revokeAllUserTokens(userId: string): Promise<void> {
        let cursor = '0';
        do {
            const [nextCursor, keys] = await redisClient.scan(
                cursor,
                'MATCH',
                `refresh:${userId}:*`,
                'COUNT',
                100
            );
            cursor = nextCursor;

            if (keys.length > 0) {
                await redisClient.del(...keys);
            }
        } while (cursor !== '0');
    }
}

export const authService = new AuthService();
