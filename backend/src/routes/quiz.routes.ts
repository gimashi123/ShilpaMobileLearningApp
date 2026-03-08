import { Router, Request, Response } from 'express';
import Quiz from '../models/Quiz';

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
                    grade,
                    type,
                },
            },
            { $sample: { size: 10 } },
            {
                $project: {
                    question: 1,
                    grade: 1,
                    type: 1,
                    subject: 1,
                    // 🔐 hide answer from frontend
                },
            },
        ]);

        res.json({
            total: quizzes.length,
            quizzes,
        });
    } catch (error: any) {
        res.status(500).json({ error: error.message });
    }
});

export default router;