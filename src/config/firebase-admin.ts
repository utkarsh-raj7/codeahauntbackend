import { initializeApp, cert, getApps } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';

const projectId = process.env.FIREBASE_PROJECT_ID;
const clientEmail = process.env.FIREBASE_ADMIN_CLIENT_EMAIL;
const privateKey = process.env.FIREBASE_ADMIN_PRIVATE_KEY?.replace(/\\n/g, '\n');

if (!getApps().length && projectId && clientEmail && privateKey) {
    initializeApp({
        credential: cert({ projectId, clientEmail, privateKey })
    });
}

export const adminAuth = getApps().length ? getAuth() : null;
