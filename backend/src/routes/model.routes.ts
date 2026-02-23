import express, { Request, Response, Router } from 'express';
import axios, { AxiosError } from 'axios';
import logger from '../config/logger.conf';
import multer from 'multer';
import fs from 'fs';
import path from 'path';

const router = Router();

// Configure multer for video uploads

const storage = multer.diskStorage({
  destination: 'uploads/videos/',
  filename: (req, file, cb) => {
    const ext = path.extname(file.originalname);   // ✅ get real extension
    const uniqueName = Date.now() + '-' + Math.round(Math.random() * 1E9);
    cb(null, uniqueName + ext);                    // ✅ keep extension
  }
});


const videoUpload = multer({
  storage,
  limits: {
    fileSize: 500 * 1024 * 1024
  },
  fileFilter: (req, file, cb) => {
    const allowedMimes = [
      'video/mp4',
      'video/quicktime',
      'video/x-msvideo',
      'video/x-matroska',
      'video/webm'
    ];

    if (allowedMimes.includes(file.mimetype)) cb(null, true);
    else cb(new Error('Only video files are allowed'));
  }
});

// Python server configuration
const PYTHON_SERVER_URL = process.env.PYTHON_SERVER_URL || 'http://localhost:8000';

/**
 * Health check endpoint to verify Python server is running
 */
router.get('/hearing-impairment/health', async (req: Request, res: Response) => {
  try {
    const response = await axios.get(`${PYTHON_SERVER_URL}/api/hearing-impairment/health`, {
      timeout: 5000
    });
    
    res.json({
      status: 'healthy',
      python_server: response.data,
      backend_ready: true
    });
  } catch (error) {
    const axiosError = error as AxiosError;
    logger.error('Python server health check failed:', axiosError.message);
    
    res.status(503).json({
      status: 'unhealthy',
      python_server: axiosError.message,
      backend_ready: false,
      python_server_url: PYTHON_SERVER_URL
    });
  }
});



/**
 * Predict sign number from video file
 * 
 * Form data:
 * - video: Video file (required)
 * - description: Optional description
 */
router.post('/hearing-impairment/predict-video', videoUpload.single('video'), async (req: Request, res: Response) => {
  let videoPath: string | null = null;

  try {
    // Check if file was uploaded
    if (!req.file) {
      return res.status(400).json({
        success: false,
        message: 'No video file provided. Please upload a video file.'
      });
    }

    videoPath = req.file.path;
    const { description } = req.body;

    const ext = path.extname(req.file.originalname);
    logger.info(`Processing video for prediction: ${req.file.filename} (ext: ${ext})`);

    // Create FormData to send video to Python server
    const FormData = require('form-data');
    const form = new FormData();

    form.append('video', fs.createReadStream(videoPath), {
      filename: req.file.originalname,   // ✅ important
      contentType: req.file.mimetype     // ✅ important
    });

    if (description) {
      form.append('description', description);
    }

    // Call Python API with video
    const response = await axios.post(
      `${PYTHON_SERVER_URL}/api/hearing-impairment/predict-video`,
      form,
      {
        headers: form.getHeaders(),
        timeout: 120000 // 2 minute timeout for video processing
      }
    );

    logger.info(`Video prediction successful for ${req.file.filename}`);

    // Return prediction result
    res.json({
      success: true,
      ...response.data
    });

  } catch (error) {
    const axiosError = error as AxiosError;
    
    logger.error('Video prediction failed:', {
      error: axiosError.message,
      status: axiosError.status,
      python_server: PYTHON_SERVER_URL
    });

    if (axiosError.response?.status === 400) {
      return res.status(400).json({
        success: false,
        message: axiosError.response.data
      });
    }

    res.status(503).json({
      success: false,
      message: 'Video processing service unavailable',
      error: axiosError.message,
      python_server_url: PYTHON_SERVER_URL
    });

  } finally {
    // Clean up uploaded video file
    if (videoPath) {
      try {
        fs.unlinkSync(videoPath);
        logger.info(`Cleaned up temporary video: ${videoPath}`);
      } catch (err) {
        logger.warn(`Failed to delete temporary video ${videoPath}:`, err);
      }
    }
  }
});

export default router;
