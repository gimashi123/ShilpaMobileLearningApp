import { z } from "zod";

export const registerSchema = z.object({
  name: z.string(),
  email: z.string().email(),
  password: z.string().min(6),

  // role – if omitted, controller will default to "student"
  role: z.enum(["student", "parent", "teacher", "admin"]).optional(),

  // OPTIONAL HERE – controller will enforce for students
  disabilityType: z
    .enum(["visual", "hearing", "physical", "cognitive"])
    .optional(),

  grade: z.union([z.string(), z.number()]).optional(),
  age: z.union([z.string(), z.number()]).optional(),
});

export const loginSchema = z.object({
  email: z.string().email(),
  password: z.string().min(6),
});
