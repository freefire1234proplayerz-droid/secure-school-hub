import { query } from '../db.js';

export async function createNotification(userId, title, body, type) {
  if (!userId) return null;
  const result = await query(
    `INSERT INTO notifications (user_id, title, body, type, created_at)
     VALUES ($1, $2, $3, $4, NOW())
     RETURNING id, title, body, type, created_at`,
    [userId, title, body, type],
  );
  return result.rows[0] ?? null;
}

export async function notifyAllParents(title, body, type) {
  const result = await query(
    `SELECT DISTINCT parent_user_id AS id
     FROM students
     WHERE parent_user_id IS NOT NULL`,
    [],
  );
  const rows = [];
  for (const row of result.rows) {
    const notification = await createNotification(row.id, title, body, type);
    if (notification) rows.push(notification);
  }
  return rows;
}

export async function notifyAllTeachers(title, body, type) {
  const result = await query(
    "SELECT id FROM users WHERE role IN ('teacher', 'admin')",
    [],
  );
  const rows = [];
  for (const row of result.rows) {
    const notification = await createNotification(row.id, title, body, type);
    if (notification) rows.push(notification);
  }
  return rows;
}
