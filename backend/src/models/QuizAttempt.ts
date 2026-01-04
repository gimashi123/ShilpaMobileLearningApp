import mongoose from "mongoose";

const AnswerSchema = new mongoose.Schema({
  qIndex: Number,
  a: Number,
  b: Number,
  correctAnswer: Number,
  userAnswer: Number,
  isCorrect: Boolean,
  timeMs: Number,
});

const QuizAttemptSchema = new mongoose.Schema(
  {
    userId: { type: mongoose.Schema.Types.ObjectId, required: true, index: true },
    operation: { type: String, enum: ["ADD", "SUB", "MUL", "DIV"], required: true },
    totalQuestions: { type: Number, default: 10 },
    correctCount: { type: Number, default: 0 },
    score: { type: Number, default: 0 },
    startedAt: { type: Date, default: Date.now },
    finishedAt: { type: Date },
    questions: [
      {
        qIndex: Number,
        a: Number,
        b: Number,
        correctAnswer: Number, // stored server-side only
      },
    ],
    answers: [AnswerSchema],
  },
  { timestamps: true }
);

export default mongoose.model("QuizAttempt", QuizAttemptSchema);
