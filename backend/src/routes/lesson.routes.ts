// src/routes/lesson.routes.ts
import { Router } from "express";
import {
  createLesson,
  getLessons,
  getMyLessons,
  completeLesson,
  getCompletedLessons,
} from "../controllers/lesson.controller";
import authMiddleware from "../middlewares/auth.middleware";
import { uploadVideoLesson } from "../middlewares/uploadVideoLessons";

const router = Router();

router.post(
  "/lessons",
  authMiddleware,
  uploadVideoLesson.any(),
  createLesson,
);

router.get("/lessons", getLessons);
router.get("/lessons/my", authMiddleware, getMyLessons);

// Student progress
router.post("/lessons/:id/complete", authMiddleware, completeLesson);
router.get("/lessons/completed", authMiddleware, getCompletedLessons);

export default router;
