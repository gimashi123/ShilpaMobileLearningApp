import mongoose from 'mongoose';
import logger from './logger.conf';

const connectDB = async (): Promise<void> => {
  const MONGODB_URI = process.env.MONGODB_URI || '';

  try {

    await mongoose.connect(MONGODB_URI, { serverSelectionTimeoutMS: 5000 } as any);
    logger.info('MongoDB connected successfully');
    return;
  } catch (error) {
    logger.error('MongoDB connection error:', error);
    // In development, in-memory MongoDB is opt-in because many systems
    // don't have all libraries required by mongodb-memory-server binaries.
    const useInMemoryDb = process.env.USE_IN_MEMORY_DB === 'true';
    if (process.env.NODE_ENV !== 'production' && useInMemoryDb) {
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
    } else if (process.env.NODE_ENV !== 'production') {
      logger.warn('Skipping in-memory MongoDB fallback. Set USE_IN_MEMORY_DB=true to enable it.');
    }
    // If we reach here, leave the application running but log the error.
  }
};

export default connectDB;
