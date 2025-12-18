import { Schema, model, Document } from "mongoose";

export interface IVideoLesson extends Document {
  disabilityType: string;
  grade: number;
  title?: string;
  description?: string;
  subject?: string;
  videoUrl: string;
  createdBy: string;
}

const VideoLessonSchema = new Schema<IVideoLesson>(
  {
    disabilityType: { type: String, required: true },
    grade: { type: Number, required: true },
    title: { type: String },
    description: { type: String },
    subject: { type: String },
    videoUrl: { type: String, required: true },
    createdBy: { type: String, required: true },
  },
  { timestamps: true }
);

export default model<IVideoLesson>("VideoLesson", VideoLessonSchema);
