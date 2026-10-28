import express from 'express';

import {
  signup,
  login,
  loginOtp,
  verifyOtp,
  getMe,
} from '../controllers/authController.js';
import { verifyToken } from '../middleware/auth.js';

export const authRoutes = express.Router();

// Public
authRoutes.post('/signup', signup);
authRoutes.post('/login', login);
authRoutes.post('/login/otp', loginOtp);
authRoutes.post('/verify-otp', verifyOtp);

// Protected
authRoutes.get('/me', verifyToken, getMe);
