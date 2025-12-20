import { loginSchema, registerSchema } from "@/types/zod/auth.schema";
import User from "../models/BlindStudent";
import { Request, Response } from "express";
import { signToken } from "@/utils/jwt.utils";
import { HTTP_STATUS } from "@/utils/http.codes";
import { errorResponse, successResponse } from "@/types/global.types";
import { AuthResponse } from "@/types/auth.types";

export const registerUser = async (req: Request, res: Response) => {
  try {
    const parsed = registerSchema.safeParse(req.body);

    if (!parsed.success) {
      return errorResponse(
        res,
        "Invalid input",
        HTTP_STATUS.BAD_REQUEST,
        parsed.error.flatten(),
      );
    }

    const data = parsed.data as any;

    const {
      name,
      email,
      password,
      role,
      disabilityType,
      grade,
      age,
    } = data;

    const existing = await User.findOne({ email });
    if (existing) {
      return errorResponse(res, "Email already in use", HTTP_STATUS.CONFLICT);
    }

    const finalRole: string = role ?? "student";

    // ------- build student subdocument only for students -------
    let student: { grade?: number; age?: number } | undefined = undefined;

    if (finalRole === "student") {
      // disabilityType REQUIRED for students
      if (!disabilityType) {
        return errorResponse(
          res,
          "disabilityType is required for students",
          HTTP_STATUS.BAD_REQUEST,
        );
      }

      if (grade === undefined || grade === null || grade === "") {
        return errorResponse(
          res,
          "Grade is required for students",
          HTTP_STATUS.BAD_REQUEST,
        );
      }

      const g = Number(grade);
      if (![3, 4, 5].includes(g)) {
        return errorResponse(
          res,
          "Grade must be 3, 4 or 5",
          HTTP_STATUS.BAD_REQUEST,
        );
      }

      const ageNum =
        age !== undefined && age !== null && age !== ""
          ? Number(age)
          : undefined;

      student = {
        grade: g,
        ...(ageNum ? { age: ageNum } : {}),
      };
    }

    const user = new User({
      name,
      email,
      password,
      role: finalRole,
      ...(disabilityType ? { disabilityType } : {}),
      ...(student ? { student } : {}),
    });

    await user.save();

    const response = createLoginResponse(user);
    return successResponse(
      res,
      "User registered successfully",
      response,
      HTTP_STATUS.CREATED,
    );
  } catch (err: any) {
    // TEMP: help debugging instead of generic "Server error"
    console.error("REGISTER_ERROR", err);

    // If it is a Mongoose validation error, surface message
    if (err.name === "ValidationError") {
      return errorResponse(
        res,
        err.message,
        HTTP_STATUS.BAD_REQUEST,
      );
    }

    return errorResponse(
      res,
      "Server error",
      HTTP_STATUS.INTERNAL_SERVER_ERROR,
    );
  }
};

export const loginUser = async (req: Request, res: Response) => {
  try {
    const parsed = loginSchema.safeParse(req.body);
    if (!parsed.success) {
      return errorResponse(
        res,
        "Invalid input",
        HTTP_STATUS.BAD_REQUEST,
        parsed.error.flatten(),
      );
    }

    const { email, password } = parsed.data;
    const user = await User.findOne({ email }).select("+password");
    if (!user) {
      return errorResponse(res, "Invalid credentials", HTTP_STATUS.BAD_REQUEST);
    }

    const ok = await (user as any).comparePassword(password);
    if (!ok) {
      return errorResponse(res, "Invalid credentials", HTTP_STATUS.BAD_REQUEST);
    }

    const response = createLoginResponse(user);
    return successResponse(res, "Login successful", response, HTTP_STATUS.OK);
  } catch (err) {
    console.error("LOGIN_ERROR", err);
    return errorResponse(
      res,
      "Server error",
      HTTP_STATUS.INTERNAL_SERVER_ERROR,
    );
  }
};

export const getMe = async (req: any, res: Response) => {
  try {
    const user = await User.findById(req.user.id);
    if (!user) {
      return errorResponse(res, "User not found", HTTP_STATUS.NOT_FOUND);
    }

    return successResponse(res, "Profile fetched", {
      id: user.id,
      name: user.name,
      email: user.email,
      role: user.role,
      disabilityType: user.disabilityType,
      student: user.student,
    });
  } catch (err) {
    console.error("GET_ME_ERROR", err);
    return errorResponse(
      res,
      "Server error",
      HTTP_STATUS.INTERNAL_SERVER_ERROR,
    );
  }
};

const createLoginResponse = (user: any): AuthResponse => {
  const token = signToken(user.id, user.role);
  return {
    token,
    user: {
      id: user.id,
      name: user.name,
      email: user.email,
      role: user.role,
      disabilityType: user.disabilityType,
      student: user.student,
    },
  };
};
