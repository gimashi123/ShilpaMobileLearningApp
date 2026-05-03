import mongoose, { Schema, Document } from "mongoose";

export interface ILessonProgress extends Document {
  userId: mongoose.Types.ObjectId;
  lessonId: mongoose.Types.ObjectId;
  completedAt: Date;
}

const LessonProgressSchema = new Schema<ILessonProgress>(
  {
    userId: {
      type: Schema.Types.ObjectId,
      ref: "User",
      required: true,
      index: true,
    },
    lessonId: {
      type: Schema.Types.ObjectId,
      ref: "VideoLesson",
      required: true,
    },
    completedAt: {
      type: Date,
      default: Date.now,
    },
  },
  { timestamps: true }
);

// Ensure a user can only have one completion record per lesson
LessonProgressSchema.index({ userId: 1, lessonId: 1 }, { unique: true });

export default mongoose.model<ILessonProgress>("LessonProgress", LessonProgressSchema);
