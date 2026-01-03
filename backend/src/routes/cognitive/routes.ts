import { Router } from "express";
import { createLdPrediction } from "../../controllers/cognitive/controller";

const router = Router();

// POST /api/ld-predictions
router.post("/ld-predictions", createLdPrediction);

export default router;
