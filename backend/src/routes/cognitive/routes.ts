import { Router } from "express";
import {
  createLdPrediction,
  getLdHistoryByStudentId,
  getIqGameConfig,
  getMatchImageItems,
  getMatchNumberItems,
  getMatchPatternTypes,
  getMatchSoundItems,
} from "../../controllers/cognitive/controller";

const router = Router();

// POST /api/ld-predictions
router.post("/ld-predictions", createLdPrediction);

// GET /api/ld-history/:studentId
router.get("/ld-history/:studentId", getLdHistoryByStudentId);

// GET /api/cognitive/match-image-items
router.get("/match-image-items", getMatchImageItems);

// GET /api/cognitive/match-number-items
router.get("/match-number-items", getMatchNumberItems);

// GET /api/cognitive/match-sound-items
router.get("/match-sound-items", getMatchSoundItems);

// GET /api/cognitive/match-pattern-types
router.get("/match-pattern-types", getMatchPatternTypes);

// GET /api/cognitive/iq-game-config
router.get("/iq-game-config", getIqGameConfig);

export default router;
