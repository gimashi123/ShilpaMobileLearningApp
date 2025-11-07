import express, { Express, Request, Response, NextFunction } from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import path from 'path';
import crypto from 'crypto';
import connectDB from './config/db.conf';
import authRouter from './routes/auth.routes';
import logger from './config/logger.conf';

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

// Error handling middleware
app.use((err: Error, req: Request, res: Response, next: NextFunction) => {
  logger.error("Error occurred while processing request:", err.stack);
  res.status(500).json({ message: 'Server error', error: err.message });
});

// Start the server
app.listen(port, () => {
  logger.info(`Server is running on port ${port}`);
});
