import { Schema, model, Document } from "mongoose";

export interface LdPredictionDoc extends Document {
  studentId: string;

  probs: [number, number, number];
  predLabel: "below" | "average" | "above";
  predScore: number;

  // Raw fields
  shapeTotalTouches: number;
  shapeValidTaps: number;
  shapeCorrect: number;
  shapeWrong: number;
  shapeWrongStreakMax: number;
  shapeHintsUsed: number;

  colorTotalTouches: number;
  colorValidTaps: number;
  colorCorrect: number;
  colorWrong: number;
  colorHintsUsed: number;
  colorWrongStreakMax: number;

  bubbleTotalTouches: number;
  bubbleValidTaps: number;
  bubbleMissedBubbles: number;
  bubbleHintsUsed: number;

  shapeAvgReactionTimeSec: number;
  colorAvgReactionTimeSec: number;
  bubbleAvgTimeBetweenPopsSec: number;

  // Derived fields
  shapeAccuracy: number;
  shapeInefficiency: number;
  shapeHintRate: number;

  colorAccuracy: number;
  colorInefficiency: number;
  colorHintRate: number;
  colorPostHintRate: number;

  bubbleValidRate: number;
  bubbleMissRate: number;

  shapeGameScore: number;
  colorGameScore: number;
  bubbleGameScore: number;

  totalGameScore: number;

  createdAt: Date;
}

const LdPredictionSchema = new Schema<LdPredictionDoc>(
  {
    studentId: { type: String, required: true, index: true },

    probs: {
      type: [Number],
      required: true,
      validate: {
        validator: (v: number[]) => Array.isArray(v) && v.length === 3,
        message: "probs must be an array of length 3",
      },
    },
    predLabel: {
      type: String,
      required: true,
      enum: ["below", "average", "above"],
    },
    predScore: { type: Number, required: true },

    shapeTotalTouches: { type: Number, required: true },
    shapeValidTaps: { type: Number, required: true },
    shapeCorrect: { type: Number, required: true },
    shapeWrong: { type: Number, required: true },
    shapeWrongStreakMax: { type: Number, required: true },
    shapeHintsUsed: { type: Number, required: true },

    colorTotalTouches: { type: Number, required: true },
    colorValidTaps: { type: Number, required: true },
    colorCorrect: { type: Number, required: true },
    colorWrong: { type: Number, required: true },
    colorHintsUsed: { type: Number, required: true },
    colorWrongStreakMax: { type: Number, required: true },

    bubbleTotalTouches: { type: Number, required: true },
    bubbleValidTaps: { type: Number, required: true },
    bubbleMissedBubbles: { type: Number, required: true },
    bubbleHintsUsed: { type: Number, required: true },

    shapeAvgReactionTimeSec: { type: Number, required: true },
    colorAvgReactionTimeSec: { type: Number, required: true },
    bubbleAvgTimeBetweenPopsSec: { type: Number, required: true },

    shapeAccuracy: { type: Number, required: true },
    shapeInefficiency: { type: Number, required: true },
    shapeHintRate: { type: Number, required: true },

    colorAccuracy: { type: Number, required: true },
    colorInefficiency: { type: Number, required: true },
    colorHintRate: { type: Number, required: true },
    colorPostHintRate: { type: Number, required: true },

    bubbleValidRate: { type: Number, required: true },
    bubbleMissRate: { type: Number, required: true },

    shapeGameScore: { type: Number, required: true },
    colorGameScore: { type: Number, required: true },
    bubbleGameScore: { type: Number, required: true },

    totalGameScore: { type: Number, required: true },
  },
  { timestamps: true }
);

export const LdPrediction = model<LdPredictionDoc>("LdPrediction", LdPredictionSchema);



