import generateBraillePdf from "@/brailpdf";
import { Router, Request, Response } from "express";

const router = Router();

// Sinhala mapping (placeholder)
const SINHALA_BRAILLE: Record<string, number[] | null> = {
  "අ": [1],
  "ක": [1, 3],
  "ද": [1, 4, 5],
  " ": null,
};

// (Used only as fallback now; numbers handled by logic)
const MATH_BRAILLE: Record<string, number[] | null> = {
  " ": null,
};

router.post("/pdf", (req: Request, res: Response) => {
  const payload = req.body || {};

  const mapping = payload.type === "sinhala" ? SINHALA_BRAILLE : MATH_BRAILLE;

  const doc = generateBraillePdf(payload, mapping);

  res.setHeader("Content-Type", "application/pdf");
  res.setHeader("Content-Disposition", 'inline; filename="quiz.pdf"');

  doc.pipe(res);
  doc.end();
});

export default router;
