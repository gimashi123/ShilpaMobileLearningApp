import { generateQuestions } from "@/quiz.generator";
import express from "express";
import QuizAttempt from "@/models/QuizAttempt";

const router = express.Router();

router.post("/start", async (req, res) => {
  try {
    const { userId, operation } = req.body;
    if (!userId || !operation) return res.status(400).json({ error: "Missing fields" });

    const questions = generateQuestions(operation, 10);

    const attempt = await QuizAttempt.create({
      userId,
      operation,
      totalQuestions: 10,
      questions,
      startedAt: new Date(),
    });

    // Send only a,b and ids (no correct answers)
    const safeQuestions = attempt.questions.map(q => ({
      id: String(q.qIndex),
      a: q.a,
      b: q.b,
    }));

    res.json({ attemptId: attempt._id, operation, questions: safeQuestions });
  } catch (e) {
    const message = e instanceof Error ? e.message : String(e);
    res.status(500).json({ error: message });
  }
});

router.post("/:attemptId/submit", async (req, res) => {
  try {
    const { attemptId } = req.params;
    const { userId, answers } = req.body;

    const attempt = await QuizAttempt.findById(attemptId);
    if (!attempt) return res.status(404).json({ error: "Attempt not found" });
    if (String(attempt.userId) !== String(userId)) return res.status(403).json({ error: "Forbidden" });

    // Map submitted answers by qIndex
    const submitted = new Map();
    for (const a of (answers || [])) {
      const idx = Number(a.id);
      submitted.set(idx, a);
    }

    let correctCount = 0;
    const answerDocs = [];

    for (const q of attempt.questions) {
      const sub = submitted.get(q.qIndex);
      const userAnswer = sub?.userAnswer ?? null;
      const isCorrect = userAnswer !== null && Number(userAnswer) === q.correctAnswer;
      if (isCorrect) correctCount++;

      answerDocs.push({
        qIndex: q.qIndex,
        a: q.a,
        b: q.b,
        correctAnswer: q.correctAnswer,
        userAnswer,
        isCorrect,
        timeMs: sub?.timeMs ?? null,
      });
    }

    const score = correctCount * 10; // example scoring

    attempt.correctCount = correctCount;
    attempt.score = score;
    attempt.finishedAt = new Date();
    attempt.answers = answerDocs as any;

    await attempt.save();

    res.json({ correctCount, score });
  } catch (e) {
    const message = e instanceof Error ? e.message : String(e);
    res.status(500).json({ error: message });
  }
});

export default router;
