import express from 'express';

import {
  signup,
  login,
  loginOtp,
  verifyOtp,
  getMe,
} from '../controllers/authController.js';
import { verifyToken } from '../middleware/auth.js';
import {
  signupValidation,
  loginValidation,
  loginOtpValidation,
  verifyOtpValidation,
} from '../middleware/validate.js';

export const authRoutes = express.Router();

// Public
authRoutes.post('/signup', signupValidation, signup);
authRoutes.post('/login', loginValidation, login);
authRoutes.post('/login/otp', loginOtpValidation, loginOtp);
authRoutes.post('/verify-otp', verifyOtpValidation, verifyOtp);

// Protected
authRoutes.get('/me', verifyToken, getMe);
