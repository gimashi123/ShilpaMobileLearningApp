// src/routes/lesson.routes.ts
import { Router } from "express";
import {
  createLesson,
  getLessons,
  getMyLessons,
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

export default router;
