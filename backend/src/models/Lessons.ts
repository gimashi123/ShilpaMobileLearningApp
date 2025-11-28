// src/models/VideoLesson.ts
import { Schema, model, Document } from 'mongoose';

export interface IVideoLesson extends Document {
  disabilityType: string;    // e.g. "visual", "hearing", "physical"
  grade: number;             // e.g. 3
  title?: string;            // optional – short label
  description?: string;      // optional
  videoUrl: string;          // /uploads/videos/xxx.mp4
  createdBy: string;         // admin id
}

const VideoLessonSchema = new Schema<IVideoLesson>(
  {
    disabilityType: { type: String, required: true, trim: true },
    grade: { type: Number, required: true },
    title: { type: String },
    description: { type: String },
    videoUrl: { type: String, required: true },
    createdBy: { type: String, required: true }
  },
  { timestamps: true }
);

export default model<IVideoLesson>('VideoLesson', VideoLessonSchema);
