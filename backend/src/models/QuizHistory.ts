import mongoose, { Document, Schema } from "mongoose";

export interface IQuizQuestion {
  questionText: string;
  correctAnswer: number;
  userAnswer: number | null;
  isCorrect: boolean;
}

export interface IQuizHistory extends Document {
  userId: mongoose.Types.ObjectId;
  disabilityType: string;
  difficultyLevel: number;
  totalQuestions: number;
  correctCount: number;
  score: number;
  questions: IQuizQuestion[];
  createdAt: Date;
  updatedAt: Date;
}

const QuizQuestionSchema = new Schema<IQuizQuestion>(
  {
    questionText: { type: String, required: true },
    correctAnswer: { type: Number, required: true },
    userAnswer: { type: Number, default: null },
    isCorrect: { type: Boolean, required: true },
  },
  { _id: false }
);

const QuizHistorySchema = new Schema<IQuizHistory>(
  {
    userId: {
      type: Schema.Types.ObjectId,
      ref: "User",
      required: true,
      index: true,
    },
    disabilityType: {
      type: String,
      enum: ["visual", "hearing", "physical", "cognitive"],
      required: true,
    },
    difficultyLevel: {
      type: Number,
      default: 1,
      min: 1,
      max: 2,
    },
    totalQuestions: {
      type: Number,
      default: 10,
    },
    correctCount: {
      type: Number,
      default: 0,
    },
    score: {
      type: Number,
      default: 0,
    },
    questions: [QuizQuestionSchema],
  },
  { timestamps: true }
);

// Compound index for efficient queries by user + disability type
QuizHistorySchema.index({ userId: 1, disabilityType: 1, createdAt: -1 });

export default mongoose.model<IQuizHistory>(
  "QuizHistory",
  QuizHistorySchema
);
