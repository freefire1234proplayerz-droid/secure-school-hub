import jwt from 'jsonwebtoken';
import dotenv from 'dotenv';

dotenv.config();

function attachUser(req, decoded) {
  const id = decoded.id ?? decoded.sub;
  req.user = {
    ...decoded,
    id,
    sub: decoded.sub ?? id,
  };
}

export function verifyToken(req, res, next) {
  const authHeader = req.headers.authorization;

  if (!authHeader) {
    return res.status(401).json({ error: 'No token' });
  }

  const token = authHeader.startsWith('Bearer ')
    ? authHeader.slice(7)
    : authHeader.split(' ')[1];

  if (!token) {
    return res.status(401).json({ error: 'No token' });
  }

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    attachUser(req, decoded);
    return next();
  } catch {
    return res.status(403).json({ error: 'Invalid token' });
  }
}

/** Backward-compatible alias used by existing API routes. */
export const authRequired = verifyToken;

export function requireRole(...roles) {
  return (req, res, next) => {
    if (!req.user?.role || !roles.includes(req.user.role)) {
      return res.status(403).json({ error: 'Forbidden' });
    }
    return next();
  };
}
