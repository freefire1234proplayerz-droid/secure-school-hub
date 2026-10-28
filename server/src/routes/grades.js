import express from 'express';
import { authRequired } from '../middleware/auth.js';
import { query } from '../db.js';

export const gradesRouter = express.Router();

gradesRouter.get('/', authRequired, async (req, res) => {
  let studentId = req.user.sub;

  if (req.user.role === 'parent') {
    const studentResult = await query(
      'SELECT id FROM students WHERE parent_user_id = $1 LIMIT 1',
      [req.user.sub],
    );
    if (studentResult.rowCount > 0) {
      studentId = studentResult.rows[0].id;
    }
  }

  const result = await query(
    'SELECT subject, score, max_score, term FROM grades WHERE student_id = $1 ORDER BY subject',
    [studentId],
  );
  return res.json({ grades: result.rows });
});

