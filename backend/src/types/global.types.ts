import { Response } from 'express';

export interface GlobalResponse {
    message: string;
    data?: any;
    success: boolean;
    code: number;
}

//helper methods for responses
export const successResponse = (
  res: Response,
  message: string,
  data?: any,
  code: number = 200
) => {
  const response: GlobalResponse = {
    message,
    data,
    success: true,
    code,
  };
  return res.status(code).json(response);
};

export const errorResponse = (
  res: Response,
  message: string,
  code: number = 500,
  data?: any
) => {
  const response: GlobalResponse = {
    message,
    data,
    success: false,
    code,
  };
  return res.status(code).json(response);
};