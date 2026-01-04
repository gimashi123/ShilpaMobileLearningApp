import { Response } from "express";
import User from "../models/BlindStudent";
import { HTTP_STATUS } from "@/utils/http.codes";
import { errorResponse, successResponse } from "@/types/global.types";
import { AuthRequest } from "@/middlewares/auth.middleware";

export const getMe = async (req: AuthRequest, res: Response) => {
  try {
    const userId = req.user?.id;
    if (!userId) {
      return errorResponse(res, "Unauthorized", HTTP_STATUS.UNAUTHORIZED);
    }

    // IMPORTANT: don't return password
    const user = await User.findById(userId).select(
      "_id name email role disabilityType student createdAt updatedAt",
    );

    if (!user) {
      return errorResponse(res, "User not found", HTTP_STATUS.NOT_FOUND);
    }

    return successResponse(
      res,
      "Me fetched",
      {
        id: user._id,
        name: user.name,
        email: user.email,
        role: user.role,
        disabilityType: user.disabilityType,
        student: user.student, // {grade, age}
      },
      HTTP_STATUS.OK,
    );
  } catch (err) {
    console.error("GET_ME_ERROR", err);
    return errorResponse(res, "Server error", HTTP_STATUS.INTERNAL_SERVER_ERROR);
  }
};

export const updateMe = async (req: AuthRequest, res: Response) => {
  try {
    const userId = req.user?.id;
    if (!userId) {
      return errorResponse(res, "Unauthorized", HTTP_STATUS.UNAUTHORIZED);
    }

    const { name, disabilityType, student } = req.body || {};

    const update: any = {};

    if (typeof name === "string" && name.trim().length > 0) {
      update.name = name.trim();
    }

    if (typeof disabilityType === "string" && disabilityType.trim().length > 0) {
      update.disabilityType = disabilityType.trim();
    }

    if (student && typeof student === "object") {
      update.student = {};
      if (student.grade !== undefined) update.student.grade = Number(student.grade);
      if (student.age !== undefined && student.age !== null && student.age !== "") {
        update.student.age = Number(student.age);
      }
    }

    const user = await User.findByIdAndUpdate(userId, update, { new: true }).select(
      "_id name email role disabilityType student",
    );

    if (!user) {
      return errorResponse(res, "User not found", HTTP_STATUS.NOT_FOUND);
    }

    return successResponse(res, "Profile updated", {
      id: user._id,
      name: user.name,
      email: user.email,
      role: user.role,
      disabilityType: user.disabilityType,
      student: user.student,
    }, HTTP_STATUS.OK);
  } catch (err) {
    console.error("UPDATE_ME_ERROR", err);
    return errorResponse(res, "Server error", HTTP_STATUS.INTERNAL_SERVER_ERROR);
  }
};