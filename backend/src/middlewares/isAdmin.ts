import { Response, NextFunction } from 'express';
import { AuthRequest } from './auth.middleware';

export default function isAdmin(req: AuthRequest, res: Response, next: NextFunction) {
    if (!req.user || req.user.role !== 'admin') {
        return res.status(403).json({ message: 'Admin only access' });
    }
    next();
}
