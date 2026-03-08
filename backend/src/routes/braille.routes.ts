import express from "express";
import multer from "multer";
import axios from "axios";
import FormData from "form-data";

import BraillePaperResult from "../models/BraillePaperResult";
import { saveFile } from "../services/file_service";

const router = express.Router();
const upload = multer();


// submit braille paper
router.post("/submit-paper", upload.single("image"), async (req, res) => {

    try {

        const { userId, quizId, correctAnswers } = req.body;

        const imageBuffer = req.file?.buffer;

        if (!imageBuffer) {
            return res.status(400).json({ message: "Image required" });
        }

        /* ----------------------------
           SAVE ANSWER IMAGE
        ---------------------------- */

        const imageUrl = await saveFile(
            imageBuffer,
            "braille_answers",
            `answer_${Date.now()}.jpg`
        );


        /* ----------------------------
           SEND IMAGE TO PYTHON MODEL
        ---------------------------- */

        const formData = new FormData();

        formData.append("image", imageBuffer, {
            filename: "answer.jpg",
            contentType: "image/jpeg"
        });

        const prediction = await axios.post(
            "http://localhost:8000/api/visual-impairment/predict-sheet",
            formData,
            {
                headers: formData.getHeaders()
            }
        );


        /* ----------------------------
           GET MODEL RESULT
        ---------------------------- */

        const predictedDigits: number[] = prediction.data.digits;

        const correct: number[] = JSON.parse(correctAnswers);


        /* ----------------------------
           CALCULATE SCORE
        ---------------------------- */

        let correctCount = 0;

        predictedDigits.forEach((digit, index) => {
            if (digit === correct[index]) {
                correctCount++;
            }
        });

        const wrongCount = predictedDigits.length - correctCount;


        /* ----------------------------
           SAVE RESULT IN DATABASE
        ---------------------------- */

        const result = await BraillePaperResult.create({

            userId,
            quizId,

            correctCount,
            wrongCount,

            correctAnswers: correct,
            predictedAnswers: predictedDigits,

            answerImageUrl: imageUrl

        });


        /* ----------------------------
           RETURN RESULT
        ---------------------------- */

        res.json({
            success: true,
            result
        });

    }
    catch (error) {

        console.error(error);

        res.status(500).json({
            success: false,
            message: "Submission failed"
        });

    }

});



router.get("/results/:userId", async (req, res) => {

    const { userId } = req.params;

    const results = await BraillePaperResult
        .find({ userId })
        .sort({ createdAt: -1 });

    res.json(results);

});

export default router;