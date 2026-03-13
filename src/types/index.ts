export class AppError extends Error {
    constructor(
        public code: string,
        public message: string,
        public http_status: number = 500
    ) {
        super(message);
        this.name = 'AppError';
    }
}

export interface Session {
    id: string;
    user_id: string;
    lab_id: string;
    status: string;
    expires_at: Date;
}
