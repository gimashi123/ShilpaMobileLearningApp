import { loginUser, registerUser, getMe } from '@/controllers/auth.controller';
import { Router } from 'express';
import requireAuth from '@/middlewares/auth.middleware';

const router = Router();

// IMPORTANT: path here is JUST '/register' (no /api/auth prefix)
router.post('/register', registerUser);

// POST /api/auth/login
router.post('/login', loginUser);

// GET /api/auth/me
router.get('/me', requireAuth, getMe);

export default router;


