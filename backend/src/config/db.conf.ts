import mongoose from 'mongoose';
import logger from './logger.conf';

const connectDB = async (): Promise<void> => {
  const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/shilpa_learning_app';

  try {
    // Use a shorter serverSelectionTimeoutMS in dev so failures are reported quickly
    await mongoose.connect(MONGODB_URI, { serverSelectionTimeoutMS: 5000 } as any);
    logger.info('MongoDB connected successfully');
    return;
  } catch (error) {
    logger.error('MongoDB connection error:', error);
    // In development (non-production), try starting an in-memory MongoDB
    if (process.env.NODE_ENV !== 'production') {
      try {
        // Dynamically import mongodb-memory-server to avoid adding it in production
        const { MongoMemoryServer } = await import('mongodb-memory-server');
        const mongod = await MongoMemoryServer.create();
        const uri = mongod.getUri();
        await mongoose.connect(uri);
        logger.debug('Connected to in-memory MongoDB for development');
        return;
      } catch (memErr) {
        logger.error('Failed to start in-memory MongoDB:', memErr);
      }
    }
    // If we reach here, leave the application running but log the error.
  }
};

export default connectDB;
