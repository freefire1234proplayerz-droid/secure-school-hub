import express from 'express';
import { authRequired } from '../middleware/auth.js';
import { query } from '../db.js';

export const gradesRouter = express.Router();

gradesRouter.get('/', authRequired, async (req, res) => {
  const result = await query(
    'SELECT subject, score, max_score, term FROM grades WHERE student_id = $1',
    [req.user.sub],
  );
  return res.json({ grades: result.rows });
});

