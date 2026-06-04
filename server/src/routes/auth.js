import express from 'express';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { authenticator } from 'otplib';
import dotenv from 'dotenv';

import { query } from '../db.js';

dotenv.config();

const OTP_STEP_SECONDS = 120;
authenticator.options = {
  step: OTP_STEP_SECONDS,
};

export const authRouter = express.Router();

// Simple login: email/password + role, returns temporary token for OTP verification.
authRouter.post('/login', async (req, res) => {
  const { email, password, role } = req.body;
  if (!email || !password || !role) {
    return res.status(400).json({ error: 'Missing fields' });
  }

  const result = await query(
    'SELECT id, password_hash, role, totp_secret FROM users WHERE email = $1',
    [email],
  );

  if (result.rowCount === 0) {
    return res.status(401).json({ error: 'Invalid credentials' });
  }

  const user = result.rows[0];
  if (user.role !== role) {
    return res.status(401).json({ error: 'Role mismatch' });
  }

  const ok = await bcrypt.compare(password, user.password_hash);
  if (!ok) {
    return res.status(401).json({ error: 'Invalid credentials' });
  }

  // Generate OTP and send via preferred channel in production.
  const secret = user.totp_secret;
  const token = authenticator.generate(secret);
  // For demo purposes, return OTP in response (DO NOT do this in production).
  const tempUserId = typeof user.id === 'number' ? user.id : parseInt(user.id, 10);
  return res.json({ otp_demo: token, tempUserId });
});

authRouter.post('/verify-otp', async (req, res) => {
  const { otp, tempUserId } = req.body;
  if (!otp || !tempUserId) {
    return res.status(400).json({ error: 'Missing fields' });
  }

  const result = await query(
    'SELECT id, email, role, totp_secret FROM users WHERE id = $1',
    [tempUserId],
  );
  if (result.rowCount === 0) {
    return res.status(400).json({ error: 'User not found' });
  }
  const user = result.rows[0];

  const isValid = authenticator.check(otp, user.totp_secret);
  if (!isValid) {
    return res.status(401).json({ error: 'Invalid OTP' });
  }

  const token = jwt.sign(
    { sub: user.id, email: user.email, role: user.role },
    process.env.JWT_SECRET,
    { expiresIn: '8h' },
  );

  return res.json({ token });
});
