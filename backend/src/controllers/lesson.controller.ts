// src/controllers/lesson.controller.ts
import { Response } from "express";
import { AuthRequest } from "../middlewares/auth.middleware";
import VideoLesson from "../models/Lessons";
import User from "../models/BlindStudent";
import LessonProgress from "../models/LessonProgress";
import { HTTP_STATUS } from "@/utils/http.codes";

// ---------- CREATE LESSON (admin upload) ----------
export const createLesson = async (req: AuthRequest, res: Response) => {
  try {
    if (!req.user || req.user.role !== "admin") {
      return res
        .status(HTTP_STATUS.FORBIDDEN)
        .json({ message: "Only admin can upload lessons" });
    }

    const { disabilityType, grade, title, subject, description } = req.body;
    if (!disabilityType || !grade) {
      return res.status(400).json({
        message: "disabilityType and grade are required",
        receivedBody: req.body,
      });
    }

    const files = (req as any).files as Express.Multer.File[] | undefined;
    const file = files?.[0];
    if (!file) {
      return res.status(400).json({ message: "Video file is required" });
    }

    const videoUrl = `/uploads/videos/${file.filename}`;

    const lesson = await VideoLesson.create({
      disabilityType,
      grade,
      title,
      subject,
      description,
      videoUrl,
      createdBy: req.user.id,
    });

    return res.status(201).json({ success: true, data: lesson });
  } catch (e: any) {
    console.error("CREATE_LESSON_ERROR:", e.message || e);
    return res
      .status(HTTP_STATUS.INTERNAL_SERVER_ERROR)
      .json({ message: "Server error creating video lesson" });
  }
};

// ---------- GET ALL LESSONS (optional filters) ----------
export const getLessons = async (req: AuthRequest, res: Response) => {
  try {
    const { disabilityType, grade, subject } = req.query;

    const filter: any = {};
    if (disabilityType) filter.disabilityType = disabilityType;
    if (grade) filter.grade = Number(grade);
    if (subject) filter.subject = subject;

    const data = await VideoLesson.find(filter).sort({ createdAt: -1 });
    return res.json({ success: true, data });
  } catch (e: any) {
    console.error("GET_LESSONS_ERROR:", e.message || e);
    return res
      .status(HTTP_STATUS.INTERNAL_SERVER_ERROR)
      .json({ message: "Server error fetching lessons" });
  }
};

// ---------- GET LESSONS FOR LOGGED-IN STUDENT ----------
export const getMyLessons = async (req: AuthRequest, res: Response) => {
  try {
    if (!req.user) {
      return res
        .status(HTTP_STATUS.UNAUTHORIZED)
        .json({ message: "Unauthorized" });
    }

    const user = await User.findById(req.user.id);
    if (!user) {
      return res
        .status(HTTP_STATUS.UNAUTHORIZED)
        .json({ message: "User not found" });
    }

    if (user.role !== "student") {
      return res
        .status(HTTP_STATUS.FORBIDDEN)
        .json({ message: "Only students can use this endpoint" });
    }

    const disabilityType = user.disabilityType;
    const grade = user.student?.grade;

    if (!disabilityType || !grade) {
      return res.status(HTTP_STATUS.BAD_REQUEST).json({
        message: "Student must have disabilityType and grade set",
      });
    }

    const lessons = await VideoLesson.find({
      disabilityType,
      grade,
    }).sort({ createdAt: -1 });

    return res.json({ success: true, data: lessons });
  } catch (e: any) {
    console.error("GET_MY_LESSONS_ERROR:", e.message || e);
    return res
      .status(HTTP_STATUS.INTERNAL_SERVER_ERROR)
      .json({ message: "Server error fetching student lessons" });
  }
};

// ---------- MARK LESSON AS COMPLETE ----------
export const completeLesson = async (req: AuthRequest, res: Response) => {
  try {
    if (!req.user) {
      return res.status(HTTP_STATUS.UNAUTHORIZED).json({ message: "Unauthorized" });
    }

    const lessonId = req.params.id;
    const userId = req.user.id;

    // Check if lesson exists
    const lesson = await VideoLesson.findById(lessonId);
    if (!lesson) {
      return res.status(404).json({ message: "Lesson not found" });
    }

    // Create or update progress (upsert logic via unique index in model)
    await LessonProgress.findOneAndUpdate(
      { userId, lessonId },
      { completedAt: new Date() },
      { upsert: true, new: true }
    );

    return res.json({ success: true, message: "Lesson marked as complete" });
  } catch (e: any) {
    console.error("COMPLETE_LESSON_ERROR:", e.message || e);
    return res
      .status(HTTP_STATUS.INTERNAL_SERVER_ERROR)
      .json({ message: "Server error marking lesson complete" });
  }
};

// ---------- GET COMPLETED LESSONS ----------
export const getCompletedLessons = async (req: AuthRequest, res: Response) => {
  try {
    if (!req.user) {
      return res.status(HTTP_STATUS.UNAUTHORIZED).json({ message: "Unauthorized" });
    }

    const userId = req.user.id;
    const progress = await LessonProgress.find({ userId }).populate("lessonId");

    return res.json({ success: true, data: progress });
  } catch (e: any) {
    console.error("GET_COMPLETED_LESSONS_ERROR:", e.message || e);
    return res
      .status(HTTP_STATUS.INTERNAL_SERVER_ERROR)
      .json({ message: "Server error fetching completed lessons" });
  }
};
