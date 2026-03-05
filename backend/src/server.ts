import express, { Express, Request, Response, NextFunction } from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import path from 'path';
import crypto from 'crypto';
import fs from 'fs';
import multer from 'multer';
import connectDB from './config/db.conf';
import authRouter from './routes/auth.routes';
import logger from './config/logger.conf';
import lessonRoutes from './routes/lesson.routes';
import brailleRoutes from './routes/braill';
import sttRoutes from "./routes/stt.routes";
import meRoutes from './routes/user.routes';
import modelRoutes from './routes/model.routes';
import { spawn } from 'child_process';
import cogvitive from './routes/cognitive/routes';
import quizRoutes from "@routes/quiz.routes";





// Load .env from the backend root (process.cwd()) first, then fall back to src/.env
dotenv.config({ path: path.resolve(process.cwd(), '.env') });
if (!process.env.MONGODB_URI) {
  dotenv.config({ path: path.resolve(__dirname, '.env') });
}

// Ensure JWT_SECRET exists. In production we fail-fast. In development
// generate a temporary secret so the server can run without blocking dev flow.
if (!process.env.JWT_SECRET) {
  if (process.env.NODE_ENV === 'production') {
    logger.error('FATAL: Missing JWT_SECRET in environment. Add JWT_SECRET to your .env file.');
    process.exit(1);
  } else {
    const tempSecret = crypto.randomBytes(32).toString('hex');
    process.env.JWT_SECRET = tempSecret;
    logger.warn('WARNING: JWT_SECRET not set — generated a temporary secret for development.');
  }
}

const app: Express = express();
const port = process.env.PORT || 3000;

// Configure multer for file uploads
const upload = multer({ dest: 'uploads/' });

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Handle invalid JSON payloads from express.json()
app.use((err: any, req: Request, res: Response, next: NextFunction) => {
  if (err instanceof SyntaxError && 'body' in err) {
    logger.error('Invalid JSON received:', err.message);
    return res.status(400).json({ message: 'Invalid JSON', error: err.message });
  }
  next(err);
});

// Connect to MongoDB
connectDB();

// Basic route
app.get('/', (req: Request, res: Response) => {
  res.send('Shilpa Mobile Learning App API');
});

// Mount API routes
app.use('/api/auth', authRouter);
app.use('/api/models', modelRoutes);

// Error handling middleware
app.use((err: Error, req: Request, res: Response, next: NextFunction) => {
  logger.error("Error occurred while processing request:", err.stack);
  res.status(500).json({ message: 'Server error', error: err.message });
});

// Start the server
app.listen({
  port: port,
  host: '0.0.0.0'
}, () => {
  logger.info(`Server is running on port ${port}`);
});

//model all paths below
// ================================
// Sign language number prediction
// ================================
app.post(
  "/api/sign/predict_video",
  upload.single("video"),
  (req: Request, res: Response) => {
    if (!req.file) {
      return res.status(400).json({ error: "video file required" });
    }

    const videoPath = req.file.path;

    // Call Python script
   const pyScript = path.join(__dirname, "predict_video.py"); // ✅ because server.ts is in src

const py = spawn("python", [pyScript, videoPath]);


    let output = "";
    let errorOutput = "";

    py.stdout.on("data", (data: { toString: () => string; }) => {
      output += data.toString();
    });

    py.stderr.on("data", (data: { toString: () => string; }) => {
      errorOutput += data.toString();
    });

    py.on("close", (code: number) => {
      // delete temp video
      try {
        fs.unlinkSync(videoPath);
      } catch (_) {}

      if (code !== 0) {
        return res.status(500).json({
          error: "Python model failed",
          details: errorOutput,
        });
      }

      try {
        const result = JSON.parse(output);
        return res.json(result);
      } catch (e) {
        return res.status(500).json({
          error: "Invalid model response",
          raw: output,
          details: errorOutput,
        });
      }
    });
  }
);


// Mount lesson routes
app.use('/uploads', express.static(path.join(__dirname, '../uploads')));
app.use('/api', lessonRoutes);

app.use("/api/quizzes", require("./routes/quiz").default);


app.use("/api/braille", brailleRoutes);

app.use("/api", sttRoutes);

app.use("/api", meRoutes);
// Cognitive routes
app.use("/api/cognitive", cogvitive);

app.use('/api/quizzes', quizRoutes);
