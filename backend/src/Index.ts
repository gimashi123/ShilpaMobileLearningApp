import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import dotenv from 'dotenv';
import mongoose from 'mongoose';
import authRoutes from './routes/auth.routes';   // << correct import
import logger from './config/logger.conf';

dotenv.config();

const app = express();
app.use(helmet());
app.use(cors({ origin: '*' }));
app.use(express.json());

app.get('/health', (_req, res) => res.json({ status: 'ok' }));

// This line makes POST /api/auth/register exist
app.use('/api/auth', authRoutes);

app.all('*', (req, res) =>
  res.status(404).json({ message: 'Not found', path: req.path, method: req.method })
);

const PORT = process.env.PORT || 3000;
mongoose.connect(process.env.MONGO_URI as string).then(() => {
  logger.info(`Server running at http://localhost:${PORT}`);
  app.listen(PORT);
});
