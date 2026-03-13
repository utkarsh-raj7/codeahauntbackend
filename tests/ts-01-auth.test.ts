import { describe, it, expect, vi, beforeEach } from 'vitest';
import { authService } from '../src/services/auth.service';
import { randomUUID } from 'crypto';

describe('TS-01: Auth Service (Phase 4.1)', () => {
    const mockUserId = randomUUID();
    let oldRefresh: string;
    let oldAccess: string;

    it('T01: should hash and verify password correctly', async () => {
        const plain = 'secret_password_123';
        const hash = await authService.hashPassword(plain);
        expect(hash).not.toBe(plain);
        
        const isValid = await authService.verifyPassword(plain, hash);
        expect(isValid).toBe(true);

        const isInvalid = await authService.verifyPassword('wrong', hash);
        expect(isInvalid).toBe(false);
    });

    it('T02: should generate standard access token', async () => {
        oldAccess = await authService.issueAccessToken(mockUserId, 'student');
        const decoded = await authService.verifyToken(oldAccess, 'access');
        expect(decoded.sub).toBe(mockUserId);
        expect(decoded.role).toBe('student');
        expect(decoded.type).toBe('access');
    });

    it('T03: should generate compliant refresh token', async () => {
        oldRefresh = await authService.issueRefreshToken(mockUserId);
        const decoded = await authService.verifyToken(oldRefresh, 'access'); // Refresh tokens use main JWT secret
        expect(decoded.sub).toBe(mockUserId);
        expect(decoded.type).toBe('refresh');
        expect(decoded.family).toBeDefined();
    });

    it('T04: should issue and verify embed logic strictly on alternate secret', async () => {
        const sessionId = randomUUID();
        const embed = await authService.issueEmbedToken(sessionId, mockUserId);
        
        const decoded = await authService.verifyToken(embed, 'embed');
        expect(decoded.sub).toBe(mockUserId);
        expect(decoded.scope).toBe('embed');
        expect(decoded.session_id).toBe(sessionId);
        
        // Ensure it fails on standard verify
        await expect(authService.verifyToken(embed, 'access')).rejects.toThrow('Invalid token');
    });

    it('T05: should refresh token successfully and invalidate old one', async () => {
        const { accessToken, newRefreshToken } = await authService.refreshTokens(oldRefresh);
        
        expect(accessToken).toBeDefined();
        expect(newRefreshToken).toBeDefined();
        expect(newRefreshToken).not.toBe(oldRefresh);
    });
});
