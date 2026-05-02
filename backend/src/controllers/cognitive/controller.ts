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

function shuffleItems<T>(items: T[]): T[] {
  const copy = [...items];
  for (let i = copy.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [copy[i], copy[j]] = [copy[j], copy[i]];
  }
  return copy;
}

const MATCH_IMAGE_ITEMS = [
  { id: "monkey", asset: "assets/images/cognitive/monkey.png" },
  { id: "panda", asset: "assets/images/cognitive/panda.png" },
  { id: "dog", asset: "assets/images/cognitive/dog.png" },
  { id: "cat", asset: "assets/images/cognitive/cat.png" },
  { id: "car", asset: "assets/images/cognitive/car.png" },
  { id: "bell", asset: "assets/images/cognitive/bell.png" },
  { id: "apple", asset: "assets/images/cognitive/apple.png" },
  { id: "ball", asset: "assets/images/cognitive/ball.png" },
];

export async function getMatchImageItems(req: Request, res: Response) {
  try {
    const rawLimit = Number(req.query.limit);
    const hasValidLimit = Number.isFinite(rawLimit) && rawLimit > 0;
    const limit = hasValidLimit
      ? Math.min(Math.floor(rawLimit), MATCH_IMAGE_ITEMS.length)
      : MATCH_IMAGE_ITEMS.length;

    const items = shuffleItems(MATCH_IMAGE_ITEMS).slice(0, limit);
    return res.json({ ok: true, items });
  } catch (err) {
    return res.status(500).json({
      ok: false,
      message: "Failed to fetch match image items",
    });
  }
}

const MATCH_NUMBER_ITEMS = [
  { value: 1, word: "එක" },
  { value: 2, word: "දෙක" },
  { value: 3, word: "තුන" },
  { value: 4, word: "හතර" },
  { value: 5, word: "පහ" },
  { value: 6, word: "හය" },
  { value: 7, word: "හත" },
  { value: 8, word: "අට" },
  { value: 9, word: "නවය" },
];

export async function getMatchNumberItems(req: Request, res: Response) {
  try {
    const rawLimit = Number(req.query.limit);
    const hasValidLimit = Number.isFinite(rawLimit) && rawLimit > 0;
    const limit = hasValidLimit
      ? Math.min(Math.floor(rawLimit), MATCH_NUMBER_ITEMS.length)
      : MATCH_NUMBER_ITEMS.length;

    const items = shuffleItems(MATCH_NUMBER_ITEMS).slice(0, limit);
    return res.json({ ok: true, items });
  } catch (err) {
    return res.status(500).json({
      ok: false,
      message: "Failed to fetch match number items",
    });
  }
}

const MATCH_SOUND_ITEMS = [
  {
    id: "dog",
    soundAsset: "sounds/cognitive/dog.mp3",
    imageAsset: "assets/images/cognitive/dog.png",
  },
  {
    id: "bell",
    soundAsset: "sounds/cognitive/bell.mp3",
    imageAsset: "assets/images/cognitive/bell.png",
  },
  {
    id: "cat",
    soundAsset: "sounds/cognitive/cat.mp3",
    imageAsset: "assets/images/cognitive/cat.png",
  },
  {
    id: "car",
    soundAsset: "sounds/cognitive/car.mp3",
    imageAsset: "assets/images/cognitive/car.png",
  },
];

export async function getMatchSoundItems(req: Request, res: Response) {
  try {
    const rawLimit = Number(req.query.limit);
    const hasValidLimit = Number.isFinite(rawLimit) && rawLimit > 0;
    const limit = hasValidLimit
      ? Math.min(Math.floor(rawLimit), MATCH_SOUND_ITEMS.length)
      : MATCH_SOUND_ITEMS.length;

    const items = shuffleItems(MATCH_SOUND_ITEMS).slice(0, limit);
    return res.json({ ok: true, items });
  } catch (err) {
    return res.status(500).json({
      ok: false,
      message: "Failed to fetch match sound items",
    });
  }
}

const MATCH_PATTERN_TYPES = [
  { type: "colors", bank: ["🔵", "🔴", "🟡", "🟢"] },
  { type: "shapes", bank: ["⬛", "🟢", "🔺", "⭐"] },
  { type: "numbers", bank: ["1", "2", "3", "4", "5"] },
];

export async function getMatchPatternTypes(req: Request, res: Response) {
  try {
    const items = shuffleItems(MATCH_PATTERN_TYPES);
    return res.json({ ok: true, items });
  } catch (err) {
    return res.status(500).json({
      ok: false,
      message: "Failed to fetch match pattern types",
    });
  }
}

const IQ_GAME_CONFIG = {
  shapes: ["circle", "square", "triangle", "rectangle"],
  colorOptions: {
    රතු: "#DC143C",
    නිල්: "#87CEEB",
    කොල: "#00FF00",
    කහ: "#FFFF00",
  },
  bubbleColors: ["#FF0000", "#0000FF", "#00AA00", "#FFFF00", "#800080", "#FFA500"],
};

export async function getIqGameConfig(req: Request, res: Response) {
  try {
    return res.json({ ok: true, config: IQ_GAME_CONFIG });
  } catch (err) {
    return res.status(500).json({
      ok: false,
      message: "Failed to fetch IQ game config",
    });
  }
}
