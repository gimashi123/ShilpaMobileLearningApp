import { Router, Request, Response } from 'express';
import Quiz from '../models/Quiz';
import { generateBraillePdf } from "../controllers/braillePDF.controller";
import GeneratedQuiz from "@models/GeneratedQuiz";
import requireAuth, { AuthRequest } from "../middlewares/auth.middleware";
import QuizHistory from "../models/QuizHistory";
import User from "../models/BlindStudent";
import logger from "../config/logger.conf";

const router = Router();

// Add Multiple Quizzes
router.post('/add', async (req: Request, res: Response) => {
    try {
        const { quizzes } = req.body;

        if (!Array.isArray(quizzes) || quizzes.length === 0) {
            return res.status(400).json({ message: 'No quizzes provided' });
        }

        const formatted = quizzes.map((q: any) => ({
            question: q.question,
            answer: q.answer.trim().toLowerCase(), // normalize
            grade: q.grade.replace(/\D/g, ''),
            type: q.type,
            subject: q.subject,
        }));

        const saved = await Quiz.insertMany(formatted);

        res.status(201).json({
            message: 'Quizzes saved successfully',
            total: saved.length,
        });
    } catch (error: any) {
        res.status(500).json({ error: error.message });
    }
});

router.post('/check/:id', async (req: Request, res: Response) => {
    try {
        const { userAnswer } = req.body;

        const quiz = await Quiz.findById(req.params.id);
        if (!quiz) return res.status(404).json({ message: 'Quiz not found' });

        const isCorrect =
            quiz.answer.toLowerCase().trim() ===
            userAnswer.toLowerCase().trim();

        res.json({
            correct: isCorrect,
            correctAnswer: quiz.answer,
        });
    } catch (error: any) {
        res.status(500).json({ error: error.message });
    }
});

// Get quizzes by grade
router.get('/grade/:grade', async (req: Request, res: Response) => {
    try {
        const grade = req.params.grade;

        const quizzes = await Quiz.find({ grade });

        res.json({
            grade,
            total: quizzes.length,
            quizzes
        });

    } catch (error: any) {
        res.status(500).json({ error: error.message });
    }
});
router.get("/random", async (req: Request, res: Response) => {
    try {

        const grade = String(req.query.grade || "");
        const type = String(req.query.type || "").toLowerCase();

        if (!grade || !type) {
            return res.status(400).json({
                message: "grade and type query parameters required",
            });
        }

        const quizzes = await Quiz.aggregate([
            {
                $match: {
                    grade: grade,
                    type: type,
                },
            },
            { $sample: { size: 10 } }
        ]);

        console.log("Matched quizzes:", quizzes.length);

        res.json({
            total: quizzes.length,
            quizzes,
        });

    } catch (error: any) {
        res.status(500).json({ error: error.message });
    }
});

router.get("/by-type", async (req: Request, res: Response) => {
    try {
        const grade = String(req.query.grade || "3");
        const type = String(req.query.type || "").toLowerCase();

        if (!type) {
            return res.status(400).json({
                message: "type query required"
            });
        }

        const quizzes = await Quiz.aggregate([
            {
                $match: {
                    grade,
                    type
                }
            },
            { $sample: { size: 10 } }
        ]);

        res.json({
            type,
            total: quizzes.length,
            quizzes
        });

    } catch (error: any) {
        res.status(500).json({ error: error.message });
    }
});

router.post("/generate-braille-pdf", generateBraillePdf);

router.get("/random-save", requireAuth, async (req: Request, res: Response) => {
    try {
        const { grade, subject, type } = req.query;
        const userId = (req as AuthRequest).user?.id;
        const userRole = (req as AuthRequest).user?.role;

        if (!grade || !subject || !type) {
            return res.status(400).json({
                message: "grade, subject, and type are required",
            });
        }

        const quizzes = await Quiz.aggregate([
            {
                $match: {
                    grade: String(grade),
                    subject: String(subject),
                    type: String(type),
                },
            },
            { $sample: { size: 10 } },
        ]);

        if (!quizzes.length) {
            return res.status(404).json({
                message: "No quizzes found",
            });
        }

        const generatedQuiz = await GeneratedQuiz.create({
            grade: String(grade),
            subject: String(subject),
            type: String(type),
            creatorId: userId,
            creatorRole: userRole as any,
            questions: quizzes.map((q) => ({
                questionId: q._id,
                question: q.question,
                answer: q.answer,
            })),
        });

        return res.status(200).json({
            message: "Generated quiz saved successfully",
            quizId: generatedQuiz._id,
            quizzes,
        });
    } catch (error) {
        console.error("Error generating quiz:", error);
        return res.status(500).json({
            message: "Server error while generating quiz",
        });
    }
});

router.post("/save-paper", requireAuth, async (req: Request, res: Response) => {
    try {
        const { grade, subject, type, questions } = req.body;
        const userId = (req as AuthRequest).user?.id;
        const userRole = (req as AuthRequest).user?.role;

        const generatedQuiz = await GeneratedQuiz.create({
            grade,
            subject,
            type,
            creatorId: userId,
            creatorRole: userRole as any,
            questions,
        });

        res.status(201).json({
            message: "Paper saved to dashboard",
            quizId: generatedQuiz._id,
        });
    } catch (error: any) {
        res.status(500).json({ error: error.message });
    }
});

router.get("/my-papers", requireAuth, async (req: Request, res: Response) => {
    try {
        const userId = (req as AuthRequest).user?.id;
        const papers = await GeneratedQuiz.find({ creatorId: userId }).sort({ createdAt: -1 });
        res.json({ papers });
    } catch (error: any) {
        res.status(500).json({ error: error.message });
    }
});

router.get("/paper/:id", requireAuth, async (req: Request, res: Response) => {
    try {
        const paper = await GeneratedQuiz.findById(req.params.id);
        if (!paper) return res.status(404).json({ message: "Paper not found" });
        res.json({ paper });
    } catch (error: any) {
        res.status(500).json({ error: error.message });
    }
});

router.get("/math-level1", async (req, res) => {
  try {
    const quizzes = await Quiz.find({
      grade: "3",
      subject: "math"
    }).limit(10);

    res.json(quizzes);
  } catch (error) {
    res.status(500).json({ message: "Failed to fetch quizzes" });
    }
});

// Save Quiz History
router.post('/history', requireAuth, async (req: Request, res: Response) => {
    try {
        const userId = (req as AuthRequest).user?.id;
        if (!userId) {
            return res.status(401).json({ success: false, message: "Unauthorized" });
        }

        const {
            disabilityType,
            difficultyLevel = 1,
            totalQuestions = 10,
            correctCount = 0,
            questions = [],
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

        const history = await QuizHistory.create({
            userId,
            disabilityType,
            difficultyLevel,
            totalQuestions,
            correctCount,
            score,
            questions,
        });

        const wrongCount = totalQuestions - correctCount;
        const xpGained = (correctCount * 5) - (wrongCount * 2);

        const user = await User.findById(userId);
        let totalXp = 0;
        if (user) {
            user.signGameXp = Math.max(0, (user.signGameXp || 0) + xpGained);
            await user.save();
            totalXp = user.signGameXp;
        }

        logger.info(
            `[QUIZ] Saved history for user=${userId}, disability=${disabilityType}, level=${difficultyLevel}, score=${correctCount}/${totalQuestions} (${score}%), xpGained=${xpGained}, totalXp=${totalXp}`
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
        logger.error(`[QUIZ] Error saving history: ${err.message}`);
        return res.status(500).json({ success: false, message: err.message });
    }
});

export default router;