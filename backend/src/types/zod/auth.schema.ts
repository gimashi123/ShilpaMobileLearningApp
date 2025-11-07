import z from "zod";

export const registerSchema = z.object({
  name: z.string().min(2),
  email: z.string().email(),
  password: z.string().min(6),
  role: z.enum(['student','parent','teacher','admin']).default('student'),
  student: z.object({
    grade: z.number().int().min(1).max(13).optional(),
    age: z.number().int().min(5).max(20).optional()
  }).optional()
});

export const loginSchema = z.object({
  email: z.string().email(),
  password: z.string().min(6),
});
