import generateBraillePdf from "@/brailpdf";
import { Router, Request, Response } from "express";


const router = Router();

// Replace with your OFFICIAL Sinhala braille mapping later
const SINHALA_BRAILLE: Record<string, number[] | null> = {
  "අ": [1],
  "ක": [1, 3],
  "ද": [1, 4, 5],
  " ": null,
};

// Replace with your chosen math braille mapping later
const MATH_BRAILLE: Record<string, number[] | null> = {
  "1": [1],
  "2": [1, 2],
  "3": [1, 4],
  "+": [3, 4, 6],
  "-": [3, 6],
  "=": [2, 3, 5, 6],
  "?": [2, 6],
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
