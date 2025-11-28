import { Response, NextFunction } from 'express';
import { AuthRequest } from './auth.middleware';
import { HTTP_STATUS } from '@/utils/http.codes';

export default function isAdmin(req: AuthRequest, res: Response, next: NextFunction) {
    if (!req.user || req.user.role !== 'admin') {
        return res.status(HTTP_STATUS.FORBIDDEN).json({ message: 'Admin only access' });
    }
    next();
}
