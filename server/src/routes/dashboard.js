import express from 'express';

import { authRequired } from '../middleware/auth.js';
import { query } from '../db.js';

export const dashboardRouter = express.Router();

function pct(part, total) {
  if (!total) return 0;
  return Math.round((Number(part) / Number(total)) * 100);
}

async function attendanceStats() {
  const totalResult = await query(
    'SELECT COUNT(*)::int AS total FROM students WHERE qr_code IS NOT NULL',
    [],
  );
  const presentResult = await query(
    `SELECT COUNT(DISTINCT student_id)::int AS present
     FROM attendance
     WHERE student_id IS NOT NULL
       AND marked_at::date = CURRENT_DATE`,
    [],
  );

  const totalStudents = totalResult.rows[0]?.total ?? 0;
  const presentToday = presentResult.rows[0]?.present ?? 0;

  return {
    totalStudents,
    presentToday,
    attendancePercent: pct(presentToday, totalStudents),
  };
}

dashboardRouter.get('/admin', authRequired, async (req, res) => {
  if (req.user.role !== 'admin' && req.user.role !== 'teacher') {
    return res.status(403).json({ error: 'Admin access required' });
  }

  const attendance = await attendanceStats();
  const teachersResult = await query(
    "SELECT COUNT(*)::int AS count FROM users WHERE role = 'teacher'",
    [],
  );
  const notificationsResult = await query(
    'SELECT COUNT(*)::int AS count FROM notifications WHERE read_at IS NULL',
    [],
  );
  const recentResult = await query(
    `SELECT
       COALESCE(s.name, s.first_name || ' ' || s.last_name) AS student_name,
       COALESCE(s.class_name, 'Class ' || s.grade || COALESCE(s.section, '')) AS class_name,
       a.marked_at
     FROM attendance a
     JOIN students s ON s.id = a.student_id
     WHERE a.student_id IS NOT NULL
     ORDER BY a.marked_at DESC
     LIMIT 5`,
    [],
  );

  return res.json({
    ...attendance,
    activeTeachers: teachersResult.rows[0]?.count ?? 0,
    alerts: notificationsResult.rows[0]?.count ?? 0,
    feePending: 860000,
    security: {
      serverStatus: 'Online',
      vpnStatus: 'Connected',
      encryptedMessaging: 'Enabled',
      suspiciousActivity: 2,
    },
    recentActivity: recentResult.rows.map((row) => ({
      title: `${row.student_name} marked present`,
      detail: `${row.class_name} attendance synced`,
      createdAt: row.marked_at,
      type: 'attendance',
    })),
  });
});

dashboardRouter.get('/teacher', authRequired, async (req, res) => {
  if (req.user.role !== 'teacher' && req.user.role !== 'admin') {
    return res.status(403).json({ error: 'Teacher access required' });
  }

  const attendance = await attendanceStats();
  const homeworkResult = await query(
    'SELECT COUNT(*)::int AS count FROM homework WHERE teacher_id = $1',
    [req.user.sub],
  );
  const notificationsResult = await query(
    `SELECT id, title, body, type, created_at
     FROM notifications
     WHERE user_id = $1
     ORDER BY created_at DESC
     LIMIT 15`,
    [req.user.sub],
  );
  const homeworkListResult = await query(
    `SELECT title, description, created_at
     FROM homework
     WHERE teacher_id = $1
     ORDER BY created_at DESC
     LIMIT 5`,
    [req.user.sub],
  );
  const recentResult = await query(
    `SELECT
       COALESCE(s.name, s.first_name || ' ' || s.last_name) AS student_name,
       COALESCE(s.class_name, 'Class ' || s.grade || COALESCE(s.section, '')) AS class_name,
       a.marked_at
     FROM attendance a
     JOIN students s ON s.id = a.student_id
     WHERE a.student_id IS NOT NULL
     ORDER BY a.marked_at DESC
     LIMIT 5`,
    [],
  );

  const unreadChat = notificationsResult.rows.filter((n) => n.type === 'chat').length;

  return res.json({
    ...attendance,
    homeworkSent: homeworkResult.rows[0]?.count ?? 0,
    parentAlerts: notificationsResult.rows.length,
    unreadParentMessages: unreadChat,
    classOverview: {
      homeworkCompletion: Math.min(100, (homeworkResult.rows[0]?.count ?? 0) * 12 + 40),
      feeFollowupClosed: 68,
    },
    notifications: notificationsResult.rows,
    homework: homeworkListResult.rows,
    recentActivity: recentResult.rows.map((row) => ({
      title: `${row.student_name} marked present`,
      detail: `${row.class_name} attendance synced`,
      createdAt: row.marked_at,
      type: 'attendance',
    })),
  });
});

dashboardRouter.get('/parent', authRequired, async (req, res) => {
  if (req.user.role !== 'parent' && req.user.role !== 'admin') {
    return res.status(403).json({ error: 'Parent access required' });
  }

  const gradesResult = await query(
    `SELECT subject, score, max_score, term
     FROM grades
     WHERE student_id = $1
     ORDER BY subject`,
    [req.user.sub],
  );
  const notificationsResult = await query(
    `SELECT id, title, body, type, created_at, read_at
     FROM notifications
     WHERE user_id = $1
     ORDER BY created_at DESC
     LIMIT 10`,
    [req.user.sub],
  );
  const homeworkResult = await query(
    `SELECT title, description, created_at
     FROM homework
     ORDER BY created_at DESC
     LIMIT 5`,
    [],
  );

  const childResult = await query(
    `SELECT COALESCE(name, first_name || ' ' || last_name) AS child_name
     FROM students
     WHERE parent_user_id = $1
     ORDER BY id
     LIMIT 1`,
    [req.user.sub],
  );

  const childAttendance = await query(
    `SELECT COUNT(*)::int AS present_days
     FROM attendance a
     JOIN students s ON s.id = a.student_id
     WHERE s.parent_user_id = $1
       AND a.marked_at >= NOW() - INTERVAL '30 days'`,
    [req.user.sub],
  );

  const feeReminders = notificationsResult.rows.filter((n) => n.type === 'fee').length;

  const grades = gradesResult.rows;
  const average = grades.length
    ? Math.round(
      grades.reduce(
        (sum, row) => sum + (Number(row.score) / Number(row.max_score)) * 100,
        0,
      ) / grades.length,
    )
    : 0;

  const presentDays = childAttendance.rows[0]?.present_days ?? 0;
  const attendancePercent = Math.min(100, Math.max(70, 70 + presentDays * 3));

  return res.json({
    childName: childResult.rows[0]?.child_name ?? 'Aarav Sharma',
    attendancePercent,
    gradeAverage: average,
    feeReminders: feeReminders > 0 ? feeReminders : 1,
    grades,
    notifications: notificationsResult.rows,
    homework: homeworkResult.rows,
  });
});
