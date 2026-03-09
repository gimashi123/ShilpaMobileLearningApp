import { Router } from "express";
import {getMe, updateMe, getAllStudents, getAllTeachers, getAllParents} from "../controllers/user.controller";


import requireAuth from "@/middlewares/auth.middleware";

const router = Router();

// GET /api/me
router.get("/me", requireAuth, getMe);
router.put("/me", requireAuth, updateMe);
router.get("/students", requireAuth, getAllStudents);
router.get("/teachers", requireAuth, getAllTeachers);
router.get("/parents", requireAuth, getAllParents);




export default router;
