import { loginSchema, registerSchema } from "@/types/zod/auth.schema";

import User from '../models/BlindStudent';

import { Request, Response } from "express";
import { signToken } from "@/utils/jwt.utils";
import { HTTP_STATUS } from "@/utils/http.codes";
import logger from "@/config/logger.conf";
import { errorResponse, successResponse } from "@/types/global.types";
import { AuthResponse } from "@/types/auth.types";

export const registerUser = async (req: Request, res: Response) => {

    try {
        const parsed = registerSchema.safeParse(req.body);
    
        if (!parsed.success) return errorResponse(res, "Invalid input", HTTP_STATUS.BAD_REQUEST, parsed.error.flatten());

        // Check if email already exists

        const { email } = parsed.data;
        const existing = await User.findOne({ email });
        if (existing) return errorResponse(res, "Email already in use", HTTP_STATUS.CONFLICT);

        const user = new User(parsed.data as any);
        try {
            logger.info('Registering new user: ', user.email);
            await user.save();
             logger.info('User Registered Successfully: ', user.email);
        } catch (saveErr) {
            logger.error('USER_SAVE_ERROR', saveErr && (saveErr as Error).stack ? (saveErr as Error).stack : saveErr);


            const saveMessage = process.env.NODE_ENV === 'production' ? 'Server error' : (saveErr && (saveErr as any).message ? (saveErr as any).message : 'Server error');
            return errorResponse(res, saveMessage, HTTP_STATUS.INTERNAL_SERVER_ERROR);
        }

        const response = createLoginResponse(user);

        return successResponse(res, "User registered successfully", response, HTTP_STATUS.CREATED);
    } catch (err) {
        logger.error('REGISTER_ERROR', err && (err as Error).stack ? (err as Error).stack : err);
        // In development include the error message to help debugging
        const devMessage = process.env.NODE_ENV === 'production' ? 'Server error' : (err && (err as Error).message ? (err as Error).message : 'Server error');
        return errorResponse(res, devMessage, HTTP_STATUS.INTERNAL_SERVER_ERROR);
    }
}

export const loginUser = async (req: Request, res: Response) => {

    try {
        const parsed = loginSchema.safeParse(req.body);
        if (!parsed.success) return res.status(400).json({ message: 'Invalid input', errors: parsed.error.flatten() });

        const { email, password } = parsed.data;
        const user = await User.findOne({ email }).select('+password');
        if (!user) return errorResponse(res, 'Invalid credentials', HTTP_STATUS.BAD_REQUEST);

        const ok = await (user as any).comparePassword(password);
        if (!ok) return errorResponse(res, 'Invalid credentials', HTTP_STATUS.BAD_REQUEST);


        const response = createLoginResponse(user);

        return successResponse(res, "Login successful", response, HTTP_STATUS.OK);
        
    } catch (err) {
        console.error('LOGIN_ERROR', err);
        return errorResponse(res, 'Server error', HTTP_STATUS.INTERNAL_SERVER_ERROR);
    }
}


const createLoginResponse = (user: any) : AuthResponse => {
        const token = signToken(user.id, user.role);

        return ({
            token,
            user: { id: user.id, name: user.name, email: user.email, role: user.role, student: user.student },
        });
}
    