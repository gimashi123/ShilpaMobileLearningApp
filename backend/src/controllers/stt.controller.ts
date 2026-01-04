import { Request, Response } from "express";
import axios from "axios";
import FormData from "form-data";

export const sttFromAudio = async (req: Request, res: Response) => {
  try {
    if (!req.file) {
      return res.status(400).json({ message: "Audio file is required (field name: file)" });
    }

    const pythonUrl = process.env.PY_STT_URL || "http://127.0.0.1:8001/stt";

    const form = new FormData();
    form.append("file", req.file.buffer, {
      filename: req.file.originalname || "audio.wav",
      contentType: req.file.mimetype || "audio/wav",
    });

    const r = await axios.post(pythonUrl, form, {
      headers: form.getHeaders(),
      maxBodyLength: Infinity,
      maxContentLength: Infinity,
      timeout: 120000, // 2 minutes (whisper can be slow)
    });

    return res.json({ text: r.data?.text ?? "" });
  } catch (err: any) {
    const detail =
      err?.response?.data?.detail ||
      err?.response?.data ||
      err?.message ||
      "STT failed";
    return res.status(500).json({ message: detail });
  }
};
