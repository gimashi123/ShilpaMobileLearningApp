import { Router, Response } from "express";
import requireAuth, { AuthRequest } from "../middlewares/auth.middleware";
import LessonProgress from "../models/LessonProgress";
import QuizHistory from "../models/QuizHistory";
import SignGameHistory from "../models/SignGameHistory";
import User from "../models/BlindStudent";
import logger from "../config/logger.conf";

const router = Router();

// Aggregate progress summary
router.get("/summary", requireAuth, async (req: AuthRequest, res: Response) => {
  try {
    const userId = req.user?.id;
    if (!userId) return res.status(401).json({ success: false, message: "Unauthorized" });

    // 1. Get user XP and basic info
    const user = await User.findById(userId);
    if (!user) return res.status(404).json({ success: false, message: "User not found" });

    // 2. Count completed lessons
    const completedLessonsCount = await LessonProgress.countDocuments({ userId });

    // 3. Count total quiz attempts
    const quizCount = await QuizHistory.countDocuments({ userId });

    // 4. Count total game attempts
    const gameCount = await SignGameHistory.countDocuments({ userId });

    return res.json({
      success: true,
      data: {
        totalXp: user.signGameXp || 0,
        lessonsCompleted: completedLessonsCount,
        quizzesCompleted: quizCount,
        gamesPlayed: gameCount,
        disabilityType: user.disabilityType,
        grade: user.student?.grade,
      }
    });
  } catch (err: any) {
    logger.error(`[PROGRESS] Summary error: ${err.message}`);
    return res.status(500).json({ success: false, message: err.message });
  }
});

// Fetch detailed history
router.get("/history", requireAuth, async (req: AuthRequest, res: Response) => {
  try {
    const userId = req.user?.id;
    if (!userId) return res.status(401).json({ success: false, message: "Unauthorized" });

    // Fetch recent data in parallel
    const [lessons, quizzes, games] = await Promise.all([
      LessonProgress.find({ userId }).populate("lessonId").sort({ completedAt: -1 }).limit(20),
      QuizHistory.find({ userId }).sort({ createdAt: -1 }).limit(20),
      SignGameHistory.find({ userId }).sort({ createdAt: -1 }).limit(20)
    ]);

    return res.json({
      success: true,
      data: {
        lessons,
        quizzes,
        games
      }
    });
  } catch (err: any) {
    logger.error(`[PROGRESS] History error: ${err.message}`);
    return res.status(500).json({ success: false, message: err.message });
  }
});

router.get("/by-email/:email", requireAuth, async (req: AuthRequest, res: Response) => {
  try {
    const student = await User.findOne({ email: req.params.email, role: "student" });
    if (!student) return res.status(404).json({ success: false, message: "Student not found" });

    const userId = student._id;

    // 1. Get summary
    const completedLessonsCount = await LessonProgress.countDocuments({ userId });
    const quizCount = await QuizHistory.countDocuments({ userId });
    const gameCount = await SignGameHistory.countDocuments({ userId });

    // 2. Get history
    const [lessons, quizzes, games] = await Promise.all([
      LessonProgress.find({ userId }).populate("lessonId").sort({ completedAt: -1 }).limit(10),
      QuizHistory.find({ userId }).sort({ createdAt: -1 }).limit(10),
      SignGameHistory.find({ userId }).sort({ createdAt: -1 }).limit(10)
    ]);

    return res.json({
      success: true,
      data: {
        summary: {
          name: student.name,
          totalXp: student.signGameXp || 0,
          lessonsCompleted: completedLessonsCount,
          quizzesCompleted: quizCount,
          gamesPlayed: gameCount,
          grade: student.student?.grade,
        },
        history: {
          lessons,
          quizzes,
          games
        }
      }
    });
  } catch (err: any) {
    logger.error(`[PROGRESS] By email error: ${err.message}`);
    return res.status(500).json({ success: false, message: err.message });
  }
});

export default router;
