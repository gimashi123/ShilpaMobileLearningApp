import { Request, Response } from "express";
import { z } from "zod";
import { LdPrediction } from "../../models/cognitive/LdModel";
import { Types } from "mongoose";


const BodySchema = z.object({
  studentId: z.string().min(1),

  probs: z.tuple([z.number(), z.number(), z.number()]),
  predLabel: z.enum(["below", "average", "above"]),
  predScore: z.number(),

  shapeTotalTouches: z.number(),
  shapeValidTaps: z.number(),
  shapeCorrect: z.number(),
  shapeWrong: z.number(),
  shapeWrongStreakMax: z.number(),
  shapeHintsUsed: z.number(),

  colorTotalTouches: z.number(),
  colorValidTaps: z.number(),
  colorCorrect: z.number(),
  colorWrong: z.number(),
  colorHintsUsed: z.number(),
  colorWrongStreakMax: z.number(),

  bubbleTotalTouches: z.number(),
  bubbleValidTaps: z.number(),
  bubbleMissedBubbles: z.number(),
  bubbleHintsUsed: z.number(),

  shapeAvgReactionTimeSec: z.number(),
  colorAvgReactionTimeSec: z.number(),
  bubbleAvgTimeBetweenPopsSec: z.number(),

  shapeAccuracy: z.number(),
  shapeInefficiency: z.number(),
  shapeHintRate: z.number(),

  colorAccuracy: z.number(),
  colorInefficiency: z.number(),
  colorHintRate: z.number(),
  colorPostHintRate: z.number(),

  bubbleValidRate: z.number(),
  bubbleMissRate: z.number(),
  

  shapeGameScore: z.number(),
  colorGameScore: z.number(),
  bubbleGameScore: z.number(),

  totalGameScore: z.number(),
});


export async function createLdPrediction(req: Request, res: Response) {
  console.log("===== RECEIVED FROM FLUTTER =====");
  console.log(req.body);
  console.log("================================");

  const parsed = BodySchema.safeParse(req.body);
  if (!parsed.success) {
    console.error("❌ VALIDATION FAILED:", parsed.error.flatten());
    return res.status(400).json({
      ok: false,
      message: "Invalid payload",
      errors: parsed.error.flatten(),
    });
  }

  try {
    const doc = await LdPrediction.create(parsed.data);
    console.log("✅ SAVED TO MONGODB:", doc._id);
    return res.status(201).json({
      ok: true,
      id: doc._id,
      createdAt: doc.createdAt,
    });
  } catch (error) {
    console.error("❌ SAVE FAILED:", error);
    return res.status(500).json({
      ok: false,
      message: "Failed to save to database",
      error: error instanceof Error ? error.message : String(error),
    });
  }
}


export async function getLdHistoryByStudentId(req: Request, res: Response) {
  try {
    const { studentId } = req.params;

    if (!studentId || studentId.trim().length === 0) {
      return res.status(400).json({ ok: false, message: "studentId is required" });
    }

    const attempts = await LdPrediction.find({ studentId: studentId.trim() })
      .select("predLabel shapeGameScore colorGameScore bubbleGameScore totalGameScore createdAt")
      .sort({ createdAt: -1 })
      .lean();

    return res.json({ ok: true, attempts });
  } catch (err) {
    return res.status(500).json({ ok: false, message: "Server error" });
  }
}
