// src/controllers/videoLesson.controller.ts
import { Response } from 'express';
import { AuthRequest } from '../middlewares/auth.middleware';
import VideoLesson from '../models/Lessons';
import { HTTP_STATUS } from '@/utils/http.codes';

export const createLesson = async (req: AuthRequest, res: Response) => {
  try {
    const { disabilityType, grade, title, description } = req.body as any;

    if (!disabilityType || !grade) {
      return res.status(400).json({
        message: 'disabilityType and grade are required',
        receivedBody: req.body,
      });
    }

    // we use uploadVideoLesson.any(), so files are in req.files[]
    const files = (req as any).files as Express.Multer.File[] | [];
    const firstFile = files.length > 0 ? files[0] : undefined;

    if (!firstFile) {
      return res.status(400).json({ message: 'Video file is required' });
    }

    const videoUrl = `/uploads/videos/${firstFile.filename}`;

    const videoLesson = await VideoLesson.create({
      disabilityType: String(disabilityType).trim(),
      grade: Number(grade),
      title,
      description,
      videoUrl,
      createdBy: req.user!.id,
    });

    return res.status(201).json({ success: true, data: videoLesson });
  } catch (e) {
    console.error(e);
    return res.status(HTTP_STATUS.INTERNAL_SERVER_ERROR).json({ message: 'Server error creating video lesson' });
  }
};

export const getLessons = async (req: AuthRequest, res: Response) => {
  try {
    const { disabilityType, grade } = req.query;

    const filter: any = {};
    if (disabilityType) filter.disabilityType = disabilityType;
    if (grade) filter.grade = Number(grade);

    const videos = await VideoLesson.find(filter).sort({ createdAt: -1 });

    return res.json({ success: true, data: videos });
  } catch (e) {
    console.error(e);
    return res.status(HTTP_STATUS.INTERNAL_SERVER_ERROR).json({ message: 'Server error fetching video lessons' });
  }
};
