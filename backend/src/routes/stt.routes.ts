import { Router } from "express";
import multer from "multer";
import { sttFromAudio } from "../controllers/stt.controller";

const router = Router();

// Keep audio in memory (no disk)
const upload = multer({ storage: multer.memoryStorage() });

// POST /api/stt  (field name must be "file")
router.post("/stt", upload.single("file"), sttFromAudio);

export default router;
