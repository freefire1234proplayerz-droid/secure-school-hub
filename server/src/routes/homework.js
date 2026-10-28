import express from 'express';
import { authRequired } from '../middleware/auth.js';
import { query } from '../db.js';
import { notifyAllParents } from '../utils/notify.js';

export const homeworkRouter = express.Router();

async function ensureHomeworkFilesTable() {
  await query(`
    CREATE TABLE IF NOT EXISTS homework_files (
      id SERIAL PRIMARY KEY,
      homework_id INTEGER REFERENCES homework(id) ON DELETE SET NULL,
      teacher_id INTEGER REFERENCES users(id),
      file_name TEXT NOT NULL,
      file_size BIGINT,
      created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
    );
  `);
}

homeworkRouter.post('/create', authRequired, async (req, res) => {
  const { title, description } = req.body;
  if (!title) {
    return res.status(400).json({ error: 'Missing title' });
  }

  const result = await query(
    `INSERT INTO homework (teacher_id, title, description, created_at)
     VALUES ($1, $2, $3, NOW())
     RETURNING id, title, description, created_at`,
    [req.user.sub, title, description || ''],
  );
  const homework = result.rows[0];

  await notifyAllParents(
    'Homework assigned',
    `${title}: ${description || 'Please check the school app for details.'}`,
    'homework',
  );

  return res.json({ status: 'created', homework });
});

homeworkRouter.post('/attach', authRequired, async (req, res) => {
  const { fileName, size, title } = req.body;
  if (!fileName) {
    return res.status(400).json({ error: 'Missing fileName' });
  }

  await ensureHomeworkFilesTable();

  const homeworkResult = await query(
    `INSERT INTO homework (teacher_id, title, description, created_at)
     VALUES ($1, $2, $3, NOW())
     RETURNING id, title, description, created_at`,
    [
      req.user.sub,
      title || `Attachment: ${fileName}`,
      `Worksheet or file shared: ${fileName}`,
    ],
  );
  const homework = homeworkResult.rows[0];

  const fileResult = await query(
    `INSERT INTO homework_files (homework_id, teacher_id, file_name, file_size)
     VALUES ($1, $2, $3, $4)
     RETURNING id, file_name, file_size, created_at`,
    [homework.id, req.user.sub, fileName, size || 0],
  );

  await notifyAllParents(
    'Homework file uploaded',
    `Teacher shared "${fileName}" for ${homework.title}.`,
    'homework',
  );

  return res.json({
    status: 'attached',
    homework,
    file: fileResult.rows[0],
  });
});

homeworkRouter.get('/list', authRequired, async (req, res) => {
  const result = await query(
    `SELECT id, title, description, created_at
     FROM homework
     WHERE teacher_id = $1
     ORDER BY created_at DESC
     LIMIT 20`,
    [req.user.sub],
  );
  return res.json({ homework: result.rows });
});
