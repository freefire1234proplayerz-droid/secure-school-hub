import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { authenticator } from 'otplib';

import { query } from '../db.js';
import { logAudit } from '../utils/audit.js';

const SALT_ROUNDS = 10;
const JWT_EXPIRES = '7d';
const ALLOWED_ROLES = ['student', 'teacher', 'parent', 'admin'];

authenticator.options = { step: 120 };

function signToken(user) {
  const id = user.id;
  return jwt.sign(
    { id, sub: id, email: user.email, role: user.role },
    process.env.JWT_SECRET,
    { expiresIn: JWT_EXPIRES },
  );
}

function publicUser(user) {
  return {
    id: user.id,
    email: user.email,
    role: user.role,
  };
}

export async function signup(req, res) {
  try {
    const { email, password, role } = req.body;

    if (!email || !password || !role) {
      return res.status(400).json({ error: 'Email, password, and role are required' });
    }

    if (!ALLOWED_ROLES.includes(role)) {
      return res.status(400).json({ error: 'Role must be student, teacher, parent, or admin' });
    }

    if (password.length < 8) {
      return res.status(400).json({ error: 'Password must be at least 8 characters' });
    }

    const existing = await query('SELECT id FROM users WHERE email = $1', [email]);
    if (existing.rowCount > 0) {
      return res.status(409).json({ error: 'Email already registered' });
    }

    const hashedPassword = await bcrypt.hash(password, SALT_ROUNDS);
    const totpSecret = authenticator.generateSecret();

    const result = await query(
      `INSERT INTO users (email, password_hash, role, totp_secret)
       VALUES ($1, $2, $3, $4)
       RETURNING id, email, role`,
      [email.toLowerCase().trim(), hashedPassword, role, totpSecret],
    );

    const user = result.rows[0];
    const token = signToken(user);

    return res.status(201).json({
      message: 'Account created',
      token,
      user: publicUser(user),
    });
  } catch (error) {
    return res.status(500).json({ error: 'Signup failed', details: error.message });
  }
}

export async function login(req, res) {
  try {
    const { email, password, role } = req.body;

    if (!email || !password) {
      return res.status(400).json({ error: 'Email and password are required' });
    }

    const result = await query(
      'SELECT id, email, password_hash, role, status FROM users WHERE email = $1',
      [email.toLowerCase().trim()],
    );

    if (result.rowCount === 0) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    const user = result.rows[0];

    if (user.status === 'disabled') {
      await logAudit({
        req,
        actorUserId: user.id,
        targetUserId: user.id,
        action: 'login_blocked_disabled',
        category: 'login',
        detail: 'Disabled account attempted to log in',
      });
      return res.status(403).json({ error: 'Account disabled' });
    }

    if (role && user.role !== role) {
      return res.status(401).json({ error: 'Role mismatch' });
    }

    const ok = await bcrypt.compare(password, user.password_hash);
    if (!ok) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    const token = signToken(user);
    await logAudit({
      req,
      actorUserId: user.id,
      targetUserId: user.id,
      action: 'login',
      category: 'login',
      detail: 'User logged in',
      metadata: { role: user.role },
    });

    return res.json({
      token,
      user: publicUser(user),
    });
  } catch (error) {
    return res.status(500).json({ error: 'Login failed', details: error.message });
  }
}

/** Step 1: password check, returns OTP challenge (keeps Flutter 2FA flow working). */
export async function loginOtp(req, res) {
  try {
    const { email, password, role } = req.body;

    if (!email || !password || !role) {
      return res.status(400).json({ error: 'Email, password, and role are required' });
    }

    const result = await query(
      'SELECT id, password_hash, role, totp_secret, status FROM users WHERE email = $1',
      [email.toLowerCase().trim()],
    );

    if (result.rowCount === 0) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    const user = result.rows[0];

    if (user.status === 'disabled') {
      await logAudit({
        req,
        actorUserId: user.id,
        targetUserId: user.id,
        action: 'login_blocked_disabled',
        category: 'login',
        detail: 'Disabled account attempted to start OTP login',
      });
      return res.status(403).json({ error: 'Account disabled' });
    }

    if (user.role !== role) {
      return res.status(401).json({ error: 'Role mismatch' });
    }

    const ok = await bcrypt.compare(password, user.password_hash);
    if (!ok) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    const otpDemo = authenticator.generate(user.totp_secret);
    const tempUserId = typeof user.id === 'number' ? user.id : parseInt(user.id, 10);

    return res.json({ otp_demo: otpDemo, tempUserId });
  } catch (error) {
    return res.status(500).json({ error: 'OTP login failed', details: error.message });
  }
}

export async function verifyOtp(req, res) {
  try {
    const { otp, tempUserId } = req.body;

    if (!otp || !tempUserId) {
      return res.status(400).json({ error: 'OTP and tempUserId are required' });
    }

    const result = await query(
      'SELECT id, email, role, totp_secret, status FROM users WHERE id = $1',
      [tempUserId],
    );

    if (result.rowCount === 0) {
      return res.status(400).json({ error: 'User not found' });
    }

    const user = result.rows[0];
    if (user.status === 'disabled') {
      return res.status(403).json({ error: 'Account disabled' });
    }

    const isValid = authenticator.check(otp, user.totp_secret);

    if (!isValid) {
      return res.status(401).json({ error: 'Invalid OTP' });
    }

    const token = signToken(user);
    await logAudit({
      req,
      actorUserId: user.id,
      targetUserId: user.id,
      action: 'login_otp_verified',
      category: 'login',
      detail: 'User completed OTP login',
      metadata: { role: user.role },
    });

    return res.json({ token, user: publicUser(user) });
  } catch (error) {
    return res.status(500).json({ error: 'OTP verification failed', details: error.message });
  }
}

export async function getMe(req, res) {
  try {
    const userId = req.user.id ?? req.user.sub;
    const result = await query(
      "SELECT id, email, role FROM users WHERE id = $1 AND status <> 'disabled'",
      [userId],
    );

    if (result.rowCount === 0) {
      return res.status(404).json({ error: 'User not found' });
    }

    return res.json({ user: publicUser(result.rows[0]) });
  } catch (error) {
    return res.status(500).json({ error: 'Failed to load profile', details: error.message });
  }
}
