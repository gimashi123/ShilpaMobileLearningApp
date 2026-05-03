import mongoose, { Schema, Document } from "mongoose";

export interface IGeneratedQuizQuestion {
    questionId: mongoose.Types.ObjectId;
    question: string;
    answer: string | number;
}

export interface IGeneratedQuiz extends Document {
    grade: string;
    subject: string;
    type: string;
    questions: IGeneratedQuizQuestion[];
    creatorId: mongoose.Types.ObjectId;
    creatorRole: 'teacher' | 'parent';
    createdAt: Date;
}

const GeneratedQuizQuestionSchema = new Schema<IGeneratedQuizQuestion>(
    {
        questionId: {
            type: Schema.Types.ObjectId,
            ref: "Quiz",
            required: true,
        },
        question: {
            type: String,
            required: true,
        },
        answer: {
            type: Schema.Types.Mixed,
            required: true,
        },
    },
    { _id: false }
);

const GeneratedQuizSchema = new Schema<IGeneratedQuiz>(
    {
        grade: {
            type: String,
            required: true,
        },
        subject: {
            type: String,
            required: true,
        },
        type: {
            type: String,
            required: true,
        },
        questions: {
            type: [GeneratedQuizQuestionSchema],
            required: true,
        },
        creatorId: {
            type: Schema.Types.ObjectId,
            ref: "User", // Assuming a generic User model or specific ones
            required: false, // Optional for now to not break existing data
        },
        creatorRole: {
            type: String,
            enum: ['teacher', 'parent', 'admin'],
            required: false,
        },
        createdAt: {
            type: Date,
            default: Date.now,
        },
    },
    {
        versionKey: false,
    }
);

export default mongoose.model<IGeneratedQuiz>(
    "GeneratedQuiz",
    GeneratedQuizSchema
);