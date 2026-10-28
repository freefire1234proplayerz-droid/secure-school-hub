import express from 'express';
import { authRequired } from '../middleware/auth.js';
import { query } from '../db.js';
import { logAudit } from '../utils/audit.js';
import { attendanceMarkValidation } from '../middleware/validate.js';

export const attendanceRouter = express.Router();

function parseQrPayload(rawQr) {
  const qr = String(rawQr || '').trim();
  if (!qr) return null;

  try {
    const decoded = JSON.parse(qr);
    return {
      studentId: decoded.studentId ? Number(decoded.studentId) : null,
      qrCode: decoded.qrCode?.toString(),
    };
  } catch (_) {
    return {
      studentId: null,
      qrCode: qr,
    };
  }
}

function toStudentDto(row) {
  const qrPayload = JSON.stringify({
    type: 'student_attendance',
    studentId: row.id,
    qrCode: row.qr_code,
  });

  return {
    id: row.id,
    name: row.name,
    className: row.class_name,
    rollNo: row.roll_no,
    qrCode: row.qr_code,
    qrPayload,
  };
}

attendanceRouter.get('/students', authRequired, async (req, res) => {
  const result = await query(
    `SELECT
       id,
       COALESCE(name, first_name || ' ' || last_name) AS name,
       COALESCE(class_name, 'Class ' || grade || COALESCE(section, '')) AS class_name,
       COALESCE(roll_no, roll_number) AS roll_no,
       qr_code
     FROM students
     WHERE qr_code IS NOT NULL
     ORDER BY class_name, roll_no`,
    [],
  );

  return res.json({ students: result.rows.map(toStudentDto) });
});

attendanceRouter.get('/summary', authRequired, async (req, res) => {
  const studentsResult = await query('SELECT COUNT(*)::int AS total FROM students WHERE qr_code IS NOT NULL', []);
  const presentResult = await query(
    `SELECT COUNT(DISTINCT student_id)::int AS present
     FROM attendance
     WHERE student_id IS NOT NULL
       AND marked_at::date = CURRENT_DATE`,
    [],
  );
  const recentResult = await query(
    `SELECT
       COALESCE(s.name, s.first_name || ' ' || s.last_name) AS name,
       COALESCE(s.class_name, 'Class ' || s.grade || COALESCE(s.section, '')) AS class_name,
       a.marked_at
     FROM attendance a
     JOIN students s ON s.id = a.student_id
     WHERE a.student_id IS NOT NULL
     ORDER BY a.marked_at DESC
     LIMIT 5`,
    [],
  );

  const total = studentsResult.rows[0]?.total ?? 0;
  const present = presentResult.rows[0]?.present ?? 0;

  return res.json({
    totalStudents: total,
    presentToday: present,
    attendancePercent: total === 0 ? 0 : Math.round((present / total) * 100),
    recent: recentResult.rows.map((row) => ({
      studentName: row.name,
      className: row.class_name,
      markedAt: row.marked_at,
    })),
  });
});

attendanceRouter.post('/mark', authRequired, attendanceMarkValidation, async (req, res) => {
  const parsed = parseQrPayload(req.body.qr);
  if (!parsed) {
    return res.status(400).json({ error: 'Missing QR data' });
  }

  const params = [];
  const clauses = [];
  if (parsed.studentId) {
    params.push(parsed.studentId);
    clauses.push(`id = $${params.length}`);
  }
  if (parsed.qrCode) {
    params.push(parsed.qrCode);
    clauses.push(`qr_code = $${params.length}`);
  }

  const studentResult = await query(
    `SELECT
       id,
       COALESCE(name, first_name || ' ' || last_name) AS name,
       COALESCE(class_name, 'Class ' || grade || COALESCE(section, '')) AS class_name,
       COALESCE(roll_no, roll_number) AS roll_no,
       parent_user_id,
       qr_code
     FROM students
     WHERE ${clauses.join(' OR ')}
     LIMIT 1`,
    params,
  );

  if (studentResult.rowCount === 0) {
    return res.status(404).json({ error: 'Student QR not recognized' });
  }

  const student = studentResult.rows[0];
  const alreadyMarked = await query(
    `SELECT id, marked_at
     FROM attendance
     WHERE student_id = $1
       AND marked_at::date = CURRENT_DATE
     ORDER BY marked_at DESC
     LIMIT 1`,
    [student.id],
  );

  const attendanceResult = alreadyMarked.rowCount > 0
    ? alreadyMarked
    : await query(
      `INSERT INTO attendance (user_id, student_id, qr_data, marked_at)
       VALUES ($1, $2, $3, NOW())
       RETURNING id, marked_at`,
      [req.user.sub, student.id, req.body.qr],
    );

  if (alreadyMarked.rowCount === 0) {
    await logAudit({
      req,
      targetStudentId: student.id,
      action: 'attendance_marked',
      category: 'attendance_actions',
      detail: `${student.name} marked present`,
      metadata: { className: student.class_name, rollNo: student.roll_no },
    });
  }

  const markedAt = attendanceResult.rows[0].marked_at;
  let notification = null;

  if (student.parent_user_id) {
    const notificationResult = await query(
      `INSERT INTO notifications (user_id, title, body, type, created_at)
       VALUES ($1, $2, $3, 'attendance', NOW())
       RETURNING id, title, body, type, created_at`,
      [
        student.parent_user_id,
        `${student.name} entered school`,
        `${student.name} was marked present for ${student.class_name}.`,
      ],
    );
    notification = notificationResult.rows[0];
  }

  return res.json({
    status: alreadyMarked.rowCount > 0 ? 'already_marked' : 'marked',
    student: toStudentDto(student),
    markedAt,
    parentNotification: notification,
  });
});

attendanceRouter.get('/notifications', authRequired, async (req, res) => {
  const result = await query(
    `SELECT id, title, body, type, created_at, read_at
     FROM notifications
     WHERE user_id = $1
     ORDER BY created_at DESC
     LIMIT 20`,
    [req.user.sub],
  );

  return res.json({ notifications: result.rows });
});
