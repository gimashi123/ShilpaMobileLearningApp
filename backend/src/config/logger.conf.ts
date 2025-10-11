// src/utils/logger.ts

import { createLogger, format, transports } from 'winston';

const { combine, timestamp, printf, colorize, errors } = format;

// Custom log format
const logFormat = printf(({ level, message, timestamp, stack }) => {
  return `${timestamp} [${level.toUpperCase()}]: ${stack || message}`;
});

// Create logger instance
const logger = createLogger({
  level: 'warn', // captures warn and error levels
  format: combine(
    timestamp({ format: 'YYYY-MM-DD HH:mm:ss' }),
    errors({ stack: true }),
    logFormat
  ),
  transports: [
    // Save only error-level logs
    new transports.File({
      filename: 'logs/error.log',
      level: 'error',
    }),

    // Save only warning-level logs
    new transports.File({
      filename: 'logs/warn.log',
      level: 'warn',
    }),

     new transports.Console({
      level: 'info',
      format: combine(colorize(), logFormat),
    }),

  
  ],
  exitOnError: false,
});

export default logger;
