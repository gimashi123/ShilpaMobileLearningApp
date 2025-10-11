import { loginUser, registerUser } from '@/controllers/auth.controller';
import { Router } from 'express';


const router = Router();

// IMPORTANT: path here is JUST '/register' (no /api/auth prefix)
router.post('/register', registerUser);

// POST /api/auth/login
router.post('/login', loginUser);

export default router;


