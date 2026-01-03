import { Router } from "express";
import { createLdPrediction , getLdHistoryByStudentId} from "../../controllers/cognitive/controller";

const router = Router();

// POST /api/ld-predictions
router.post("/ld-predictions", createLdPrediction);

// GET /api/ld-history/:studentId
router.get("/ld-history/:studentId", getLdHistoryByStudentId);

export default router;
