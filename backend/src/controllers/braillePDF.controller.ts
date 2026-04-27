import PDFDocument from "pdfkit";
import { Request, Response } from "express";

// mm to PDF points
const mm = 2.83;

// Braille dimensions (scaled to slate)
const dotSpacing = 2.5 * mm;   // distance between dots
const cellSpacing = 6 * mm;    // distance between cells
const dotRadius = 0.7 * mm;    // guide dot size

// Braille dot patterns (6-dot system)
const brailleDots: Record<string, number[]> = {
    "1": [1,0,0,0,0,0],
    "2": [1,1,0,0,0,0],
    "3": [1,0,0,1,0,0],
    "4": [1,0,0,1,1,0],
    "5": [1,0,0,0,1,0],
    "6": [1,1,0,1,0,0],
    "7": [1,1,0,1,1,0],
    "8": [1,1,0,0,1,0],
    "9": [0,1,0,1,0,0],
    "0": [0,1,0,1,1,0],

    "+": [0,1,1,0,1,0],
    "-": [0,0,1,0,0,1],
    "x": [0,1,1,0,1,1],
    "*": [0,1,1,0,1,1],
    "/": [0,0,1,1,0,0],
    "=": [0,1,1,1,1,0],
};

// 🔵 Draw one Braille cell
function drawBrailleCell(doc: any, x: number, y: number, pattern: number[]) {

    const positions = [
        [0, 0],
        [0, dotSpacing],
        [0, dotSpacing * 2],
        [dotSpacing, 0],
        [dotSpacing, dotSpacing],
        [dotSpacing, dotSpacing * 2]
    ];

    pattern.forEach((dot, i) => {
        if (dot === 1) {
            const [dx, dy] = positions[i];

            // outline circle (guide for punching)
            doc.circle(x + dx, y + dy, dotRadius).stroke();
        }
    });
}

// 🔢 Draw full expression
function drawBrailleText(doc: any, text: string, startX: number, startY: number) {
    let x = startX;

    for (const char of text) {
        const pattern = brailleDots[char];

        if (pattern) {
            drawBrailleCell(doc, x, startY, pattern);
            x += cellSpacing;
        } else {
            x += cellSpacing / 2; // space
        }
    }
}

export const generateBraillePdf = (req: Request, res: Response) => {

    const { quizzes } = req.body;

    if (!quizzes) {
        return res.status(400).json({ message: "No quizzes provided" });
    }

    const doc = new PDFDocument({ margin: 50 });

    res.setHeader("Content-Type", "application/pdf");
    res.setHeader(
        "Content-Disposition",
        "attachment; filename=braille_quiz.pdf"
    );

    doc.pipe(res);

    // =========================
    // STUDENT PAGE
    // =========================
    doc.fontSize(20).text("Braille Maths Quiz", { align: "center" });
    doc.moveDown(2);

    let startY = 120;

    quizzes.forEach((q: any, i: number) => {

        // Question number (normal text)
        doc.fontSize(12).text(`${i + 1}.`, 50, startY);

        // Braille dots
        drawBrailleText(doc, q.question, 80, startY);

        // Answer line
        doc.moveTo(80, startY + 40)
            .lineTo(400, startY + 40)
            .stroke();

        startY += 80; // move to next row
    });

    // =========================
    // TEACHER PAGE
    // =========================
    doc.addPage();

    doc.fontSize(18).text("Teacher Answer Sheet");
    doc.moveDown();

    quizzes.forEach((q: any, i: number) => {
        doc.fontSize(12).text(`${i + 1}. ${q.answer}`);
        doc.moveDown();
    });

    doc.end();
};