import mongoose, { Document, Schema } from "mongoose";

export interface ISignGameQuestion {
  questionText: string;
  correctAnswer: number;
  userAnswer: number | null;
  isCorrect: boolean;
}

export interface ISignGameHistory extends Document {
  userId: mongoose.Types.ObjectId;
  disabilityType: string;
  difficultyLevel: number;
  totalQuestions: number;
  correctCount: number;
  score: number;
  questions: ISignGameQuestion[];
  createdAt: Date;
  updatedAt: Date;
}

const SignGameQuestionSchema = new Schema<ISignGameQuestion>(
  {
    questionText: { type: String, required: true },
    correctAnswer: { type: Number, required: true },
    userAnswer: { type: Number, default: null },
    isCorrect: { type: Boolean, required: true },
  },
  { _id: false }
);

const SignGameHistorySchema = new Schema<ISignGameHistory>(
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
    questions: [SignGameQuestionSchema],
  },
  { timestamps: true }
);

// Compound index for efficient queries by user + disability type
SignGameHistorySchema.index({ userId: 1, disabilityType: 1, createdAt: -1 });

export default mongoose.model<ISignGameHistory>(
  "SignGameHistory",
  SignGameHistorySchema
);
