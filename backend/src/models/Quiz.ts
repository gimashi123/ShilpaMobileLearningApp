import mongoose, { Document, Schema } from "mongoose";

export interface IQuiz extends Document {
    question: string;
    answer: string;
    grade: "3" | "4" | "5";
    type: string; // flexible
    subject: string;
    createdAt: Date;
    updatedAt: Date;
}

const QuizSchema: Schema = new Schema(
    {
        question: {
            type: String,
            required: true,
            trim: true,
        },

        answer: {
            type: String,
            required: true,
            trim: true,
            lowercase: true,
        },

        grade: {
            type: String,
            enum: ["3", "4", "5"],
            required: true,
        },

        // 🔥 flexible type (no enum)
        type: {
            type: String,
            required: true,
            trim: true,
            lowercase: true,
        },

        subject: {
            type: String,
            required: true,
            trim: true,
        },
    },
    { timestamps: true }
);

export default mongoose.model<IQuiz>("Quiz", QuizSchema);