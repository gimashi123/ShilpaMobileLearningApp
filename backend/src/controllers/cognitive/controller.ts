import { Request, Response } from "express";
import { z } from "zod";
import { LdPrediction } from "../../models/cognitive/LdModel";

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
});

export async function createLdPrediction(req: Request, res: Response) {
  console.log("===== RECEIVED FROM FLUTTER =====");
  console.log(req.body);
  console.log("================================");

  const parsed = BodySchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({
      ok: false,
      message: "Invalid payload",
      errors: parsed.error.flatten(),
    });
  }

  const doc = await LdPrediction.create(parsed.data);
console.log("✅ SAVED TO MONGODB:", doc._id);
  return res.status(201).json({
    ok: true,
    id: doc._id,
    createdAt: doc.createdAt,
  });
}
