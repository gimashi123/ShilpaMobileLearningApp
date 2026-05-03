import { Router, Response } from "express";
import requireAuth, { AuthRequest } from "../middlewares/auth.middleware";
import SignGameHistory from "../models/SignGameHistory";
import User from "../models/BlindStudent";
import logger from "../config/logger.conf";

const router = Router();

// All routes require authentication
router.use(requireAuth);

/**
 * POST /api/sign-game/history
 * Save a completed quiz round for the logged-in student.
 *
 * Body:
 * {
 *   disabilityType: "hearing" | "visual" | "physical" | "cognitive",
 *   difficultyLevel: 1 | 2,
 *   totalQuestions: number,
 *   correctCount: number,
 *   questions: [{ questionText, correctAnswer, userAnswer, isCorrect }]
 * }
 */
router.post("/history", async (req: AuthRequest, res: Response) => {
  try {
    const userId = req.user?.id;
    if (!userId) {
      return res.status(401).json({ success: false, message: "Not authenticated" });
    }

    const {
      disabilityType,
      difficultyLevel = 1,
      totalQuestions = 10,
      correctCount = 0,
      questions = [],
      source = "game",
    } = req.body;

    if (!disabilityType) {
      return res.status(400).json({
        success: false,
        message: "disabilityType is required",
      });
    }

    const score = totalQuestions > 0
      ? Math.round((correctCount / totalQuestions) * 100)
      : 0;

    const history = await SignGameHistory.create({
      userId,
      disabilityType,
      difficultyLevel,
      totalQuestions,
      correctCount,
      score,
      questions,
    });

    let xpGained = 0;
    const wrongCount = totalQuestions - correctCount;
    if (source === "quiz") {
      xpGained = (correctCount * 5) - (wrongCount * 2);
    } else {
      xpGained = (correctCount * 10) - (wrongCount * 2);
    }

    const user = await User.findById(userId);
    let totalXp = 0;
    if (user) {
      user.signGameXp = Math.max(0, (user.signGameXp || 0) + xpGained);
      await user.save();
      totalXp = user.signGameXp;
    }

    logger.info(
      `[SIGN_GAME] Saved history for user=${userId}, ` +
      `disability=${disabilityType}, level=${difficultyLevel}, ` +
      `score=${correctCount}/${totalQuestions} (${score}%), xpGained=${xpGained}, totalXp=${totalXp}`
    );

    return res.status(201).json({
      success: true,
      data: {
        id: history._id,
        score,
        correctCount,
        totalQuestions,
        difficultyLevel,
        xpGained,
        totalXp,
      },
    });
  } catch (err: any) {
    logger.error(`[SIGN_GAME] Error saving history: ${err.message}`);
    return res.status(500).json({ success: false, message: err.message });
  }
});

/**
 * GET /api/sign-game/level?disabilityType=hearing
 * Get the student's current difficulty level based on recent quiz history.
 *
 * Logic:
 *   - Fetch last 2 rounds for this user + disability type
 *   - If both scored >= 8/10 at the current level → nextLevel = currentLevel + 1 (max 2)
 *   - Otherwise → stay at current level
 *
 * Response:
 * { success: true, data: { currentLevel, shouldLevelUp, recentScores } }
 */
router.get("/level", async (req: AuthRequest, res: Response) => {
  try {
    const userId = req.user?.id;
    if (!userId) {
      return res.status(401).json({ success: false, message: "Not authenticated" });
    }

    const disabilityType = req.query.disabilityType as string;
    if (!disabilityType) {
      return res.status(400).json({
        success: false,
        message: "disabilityType query param is required",
      });
    }

    const user = await User.findById(userId);
    if (!user) {
      return res.status(404).json({ success: false, message: "User not found" });
    }

    const xp = user.signGameXp || 0;
    const currentLevel = xp >= 1000 ? 2 : 1;

    logger.info(
      `[SIGN_GAME] Level check for user=${userId}: ` +
      `xp=${xp}, currentLevel=${currentLevel}`
    );

    return res.json({
      success: true,
      data: {
        currentLevel,
        xp,
      },
    });
  } catch (err: any) {
    logger.error(`[SIGN_GAME] Error getting level: ${err.message}`);
    return res.status(500).json({ success: false, message: err.message });
  }
});

/**
 * GET /api/sign-game/history?disabilityType=hearing&limit=10
 * Get the student's quiz history (paginated).
 */
router.get("/history", async (req: AuthRequest, res: Response) => {
  try {
    const userId = req.user?.id;
    if (!userId) {
      return res.status(401).json({ success: false, message: "Not authenticated" });
    }

    const disabilityType = req.query.disabilityType as string;
    const limit = Math.min(parseInt(req.query.limit as string) || 10, 50);

    const filter: any = { userId };
    if (disabilityType) {
      filter.disabilityType = disabilityType;
    }

    const history = await SignGameHistory.find(filter)
      .sort({ createdAt: -1 })
      .limit(limit)
      .lean();

    return res.json({
      success: true,
      data: history,
    });
  } catch (err: any) {
    logger.error(`[SIGN_GAME] Error fetching history: ${err.message}`);
    return res.status(500).json({ success: false, message: err.message });
  }
});

export default router;
