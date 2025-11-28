import multer from 'multer';
import path from 'path';
import fs from 'fs';

// uploads/videos
const videoDir = path.join(__dirname, '../../uploads/videos');

if (!fs.existsSync(videoDir)) {
  fs.mkdirSync(videoDir, { recursive: true });
}

const storage = multer.diskStorage({
  destination: (_req, _file, cb) => cb(null, videoDir),
  filename: (_req, file, cb) => {
    const ext = path.extname(file.originalname);     // .mp4 / .mov / .webm...
    const name = Date.now() + '-' + Math.round(Math.random() * 1e9) + ext;
    cb(null, name);
  }
});

export const uploadLesson = multer({ storage });
