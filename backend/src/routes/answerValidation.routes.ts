import express from "express";
import multer from "multer";
import axios from "axios";
import FormData from "form-data";
import GeneratedQuiz from "../models/GeneratedQuiz";

const router = express.Router();
const upload = multer();

/*
POST /api/validate-answer
body:
 - quizId
 - image file
*/

router.post(
    "/validate-answer",
    upload.single("image"),
    async (req, res) => {
        try {

            const { quizId } = req.body;

            if (!quizId) {
                return res.status(400).json({
                    message: "quizId required"
                });
            }

            const quiz = await GeneratedQuiz.findById(quizId);

            if (!quiz) {
                return res.status(404).json({
                    message: "Quiz not found"
                });
            }

            if (!req.file) {
                return res.status(400).json({
                    message: "Image required"
                });
            }

            /* send image to FastAPI */

            const form = new FormData();
            form.append("images", req.file.buffer, req.file.originalname);

            const mlResponse = await axios.post(
                "http://localhost:8000/api/visual-impairment/predict-sheet",
                form,
                { headers: form.getHeaders() }
            );

            const prediction = mlResponse.data;

            const predictedNumber = prediction.number;

            /* compare answers */

            const correctAnswers = quiz.questions.map(q => q.answer);

            const result = correctAnswers.map((ans, i) => ({
                question: i + 1,
                correct: ans,
                predicted: predictedNumber,
                isCorrect: ans == predictedNumber
            }));

            res.json({
                success: true,
                prediction,
                result
            });

        } catch (err) {
            console.error(err);
            res.status(500).json({
                message: "Validation failed"
            });
        }
    }
);

export default router;