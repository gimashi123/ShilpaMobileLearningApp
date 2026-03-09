// import mongoose from "mongoose";
//
// const BraillePaperResultSchema = new mongoose.Schema(
//     {
//         userId: { type: String, required: true },
//
//         quizId: { type: String, required: true },
//
//         correctCount: Number,
//         wrongCount: Number,
//
//         correctAnswers: [Number],
//         predictedAnswers: [Number],
//
//         pdfUrl: String,
//         answerImageUrl: String
//     },
//     { timestamps: true }
// );
//
// export default mongoose.model(
//     "BraillePaperResult",
//     BraillePaperResultSchema
// );