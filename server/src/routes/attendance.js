import express from 'express';
import { authRequired } from '../middleware/auth.js';
import { query } from '../db.js';

export const attendanceRouter = express.Router();

const demoStudents = [
  {
    name: 'Aarav Sharma',
    className: 'Class 8A',
    rollNo: '08A-01',
    qrCode: 'SSHUB-STUDENT-08A-001',
  },
  {
    name: 'Isha Mehta',
    className: 'Class 8A',
    rollNo: '08A-02',
    qrCode: 'SSHUB-STUDENT-08A-002',
  },
  {
    name: 'Kabir Rao',
    className: 'Class 8A',
    rollNo: '08A-03',
    qrCode: 'SSHUB-STUDENT-08A-003',
  },
  {
    name: 'Meera Iyer',
    className: 'Class 8A',
    rollNo: '08A-04',
    qrCode: 'SSHUB-STUDENT-08A-004',
  },
];

let demoReady = false;

async function ensureDemoAttendanceData() {
  if (demoReady) return;

  await query(`
    CREATE TABLE IF NOT EXISTS students (
      id SERIAL PRIMARY KEY,
      first_name TEXT NOT NULL,
      last_name TEXT NOT NULL,
      grade INTEGER,
      section TEXT,
      roll_number TEXT UNIQUE,
      name TEXT,
      class_name TEXT,
      roll_no TEXT,
      parent_user_id INTEGER REFERENCES users(id),
      qr_code TEXT UNIQUE NOT NULL
    );
  `);

  await query('ALTER TABLE students ADD COLUMN IF NOT EXISTS name TEXT;', []);
  await query('ALTER TABLE students ADD COLUMN IF NOT EXISTS class_name TEXT;', []);
  await query('ALTER TABLE students ADD COLUMN IF NOT EXISTS roll_no TEXT;', []);
  await query('ALTER TABLE students ADD COLUMN IF NOT EXISTS parent_user_id INTEGER REFERENCES users(id);', []);
  await query('ALTER TABLE students ADD COLUMN IF NOT EXISTS qr_code TEXT;', []);
  await query(
    'CREATE UNIQUE INDEX IF NOT EXISTS students_qr_code_unique ON students(qr_code);',
    [],
  );

  await query(`
    CREATE TABLE IF NOT EXISTS notifications (
      id SERIAL PRIMARY KEY,
      user_id INTEGER REFERENCES users(id),
      title TEXT NOT NULL,
      body TEXT NOT NULL,
      type TEXT NOT NULL,
      created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
      read_at TIMESTAMP WITH TIME ZONE
    );
  `);

  await query(`
    CREATE TABLE IF NOT EXISTS attendance (
      id SERIAL PRIMARY KEY,
      user_id INTEGER REFERENCES users(id),
      qr_data TEXT NOT NULL,
      marked_at TIMESTAMP WITH TIME ZONE NOT NULL
    );
  `);

  await query(`
    ALTER TABLE attendance
    ADD COLUMN IF NOT EXISTS student_id INTEGER REFERENCES students(id);
  `);

  const parentResult = await query(
    "SELECT id FROM users WHERE role = 'parent' ORDER BY id LIMIT 1",
    [],
  );
  const parentUserId = parentResult.rows[0]?.id ?? null;

  for (const student of demoStudents) {
    const [firstName, ...lastNameParts] = student.name.split(' ');
    const lastName = lastNameParts.join(' ') || 'Student';
    await query(
      `INSERT INTO students (
         first_name,
         last_name,
         grade,
         section,
         roll_number,
         name,
         class_name,
         roll_no,
         parent_user_id,
         qr_code
       )
       VALUES ($1, $2, 8, 'A', $3, $4, $5, $6, $7, $8)
       ON CONFLICT (qr_code)
       DO UPDATE SET
         name = EXCLUDED.name,
         class_name = EXCLUDED.class_name,
         roll_no = EXCLUDED.roll_no,
         parent_user_id = COALESCE(students.parent_user_id, EXCLUDED.parent_user_id)`,
      [
        firstName,
        lastName,
        student.rollNo,
        student.name,
        student.className,
        student.rollNo,
        parentUserId,
        student.qrCode,
      ],
    );
  }

  demoReady = true;
}

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
  await ensureDemoAttendanceData();

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
  await ensureDemoAttendanceData();

  const studentsResult = await query('SELECT COUNT(*)::int AS total FROM students', []);
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

attendanceRouter.post('/mark', authRequired, async (req, res) => {
  await ensureDemoAttendanceData();

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
  await ensureDemoAttendanceData();

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
