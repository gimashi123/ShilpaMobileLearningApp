import PDFDocument from "pdfkit";
import { Request, Response } from "express";

const brailleMap: Record<string, string> = {
    "1": "⠁",
    "2": "⠃",
    "3": "⠉",
    "4": "⠙",
    "5": "⠑",
    "6": "⠋",
    "7": "⠛",
    "8": "⠓",
    "9": "⠊",
    "0": "⠚",

    "+": "⠖",
    "-": "⠤",
    "x": "⠦",
    "*": "⠦",
    "/": "⠌",
    "=": "⠶",
    " ": " "
};

function mathToBraille(expression: string) {
    let result = "";
    let inNumber = false;

    for (const char of expression) {
        if (/\d/.test(char)) {
            if (!inNumber) {
                result += "⠼";
                inNumber = true;
            }
            result += brailleMap[char];
        } else {
            inNumber = false;
            result += brailleMap[char] || char;
        }
    }

    return result;
}

export const generateBraillePdf = (req: Request, res: Response) => {

    const { quizzes } = req.body;

    if (!quizzes) {
        return res.status(400).json({ message: "No quizzes provided" });
    }

    const doc = new PDFDocument();

    res.setHeader("Content-Type", "application/pdf");
    res.setHeader(
        "Content-Disposition",
        "attachment; filename=braille_quiz.pdf"
    );

    doc.pipe(res);

    // Student page
    doc.fontSize(20).text("Braille Maths Quiz", { align: "center" });
    doc.moveDown();

    quizzes.forEach((q: any, i: number) => {

        const brailleQuestion = mathToBraille(q.question);

        doc.fontSize(14).text(`${i + 1}. ${brailleQuestion}`);
        doc.moveDown();
        doc.text("Answer: __________________");
        doc.moveDown(2);

    });

    // Teacher page
    doc.addPage();

    doc.fontSize(18).text("Teacher Answer Sheet");
    doc.moveDown();

    quizzes.forEach((q: any, i: number) => {

        const brailleAnswer = mathToBraille(q.answer || "");

        doc.text(`${i + 1}. ${q.answer} (${brailleAnswer})`);
        doc.moveDown();

    });

    doc.end();
};