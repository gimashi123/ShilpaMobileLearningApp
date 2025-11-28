// src/routes/lesson.routes.ts
import { Router } from 'express';
import requireAuth from '../middlewares/auth.middleware';
import isAdmin from '../middlewares/isAdmin';
import { uploadLesson } from '../config/upload';
import { createLesson, getLessons } from '../controllers/lesson.controller';

const router = Router();

router.post(
  '/admin/lessons',
  requireAuth,
  isAdmin,
  uploadLesson.any(),   // 👈 important
  createLesson
);

router.get('/lessons', requireAuth, getLessons);
router.get('/lessons/grade', requireAuth, getLessons);

export default router;
