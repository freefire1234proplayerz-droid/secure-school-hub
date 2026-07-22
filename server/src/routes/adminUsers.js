import express from 'express';
import bcrypt from 'bcryptjs';
import { authenticator } from 'otplib';

import { authRequired, requireRole } from '../middleware/auth.js';
import { query } from '../db.js';
import { logAudit } from '../utils/audit.js';

export const adminUsersRouter = express.Router();

const SALT_ROUNDS = 10;
const ROLES = new Set(['student', 'teacher', 'parent', 'admin']);
const STATUSES = new Set(['active', 'disabled']);

adminUsersRouter.use(authRequired, requireRole('admin'));

function normalizeEmail(email) {
  return String(email || '').trim().toLowerCase();
}

function className(grade, section) {
  if (!grade && !section) return null;
  return `Class ${grade ?? ''}${section ?? ''}`.trim();
}

function csvEscape(value) {
  const raw = value == null ? '' : String(value);
  if (!/[",\n]/.test(raw)) return raw;
  return `"${raw.replaceAll('"', '""')}"`;
}

function userDto(row) {
  return {
    id: row.id,
    email: row.email,
    role: row.role,
    firstName: row.first_name,
    lastName: row.last_name,
    phone: row.phone,
    status: row.status,
    disabledAt: row.disabled_at,
    createdAt: row.created_at,
    student: row.student_id
      ? {
          id: row.student_id,
          admissionNo: row.admission_no,
          className: row.class_name,
          grade: row.grade,
          section: row.section,
          rollNo: row.roll_no,
          parentUserId: row.parent_user_id,
          status: row.student_status,
        }
      : null,
  };
}

async function nextStudentId() {
  const result = await query(
    `SELECT COALESCE(MAX((regexp_match(admission_no, 'SSH-([0-9]+)$'))[1]::int), 0) + 1 AS next
     FROM students
     WHERE admission_no ~ '^SSH-[0-9]+$'`,
    [],
  );
  return `SSH-${String(result.rows[0]?.next ?? 1).padStart(5, '0')}`;
}

async function createUser({ email, password, role, firstName, lastName, phone }) {
  const hashedPassword = await bcrypt.hash(password, SALT_ROUNDS);
  const result = await query(
    `INSERT INTO users (
       email,
       password_hash,
       role,
       totp_secret,
       first_name,
       last_name,
       phone,
       status,
       created_at,
       updated_at
     )
     VALUES ($1, $2, $3, $4, $5, $6, $7, 'active', NOW(), NOW())
     RETURNING id, email, role, first_name, last_name, phone, status, created_at`,
    [
      normalizeEmail(email),
      hashedPassword,
      role,
      authenticator.generateSecret(),
      firstName,
      lastName,
      phone,
    ],
  );
  return result.rows[0];
}

adminUsersRouter.get('/users', async (req, res) => {
  const role = req.query.role?.toString();
  const status = req.query.status?.toString();
  const classFilter = req.query.class?.toString();
  const search = req.query.search?.toString().trim();

  const params = [];
  const where = [];

  if (role && role !== 'all') {
    params.push(role);
    where.push(`u.role = $${params.length}`);
  }

  if (status && status !== 'all') {
    params.push(status);
    where.push(`u.status = $${params.length}`);
  }

  if (classFilter && classFilter !== 'all') {
    params.push(classFilter);
    where.push(`COALESCE(s.class_name, 'Class ' || s.grade || COALESCE(s.section, '')) = $${params.length}`);
  }

  if (search) {
    params.push(`%${search}%`);
    where.push(`(
      u.email ILIKE $${params.length}
      OR u.first_name ILIKE $${params.length}
      OR u.last_name ILIKE $${params.length}
      OR s.admission_no ILIKE $${params.length}
      OR COALESCE(s.name, s.first_name || ' ' || s.last_name) ILIKE $${params.length}
    )`);
  }

  const result = await query(
    `SELECT
       u.id,
       u.email,
       u.role,
       u.first_name,
       u.last_name,
       u.phone,
       u.status,
       u.disabled_at,
       u.created_at,
       s.id AS student_id,
       s.admission_no,
       COALESCE(s.class_name, 'Class ' || s.grade || COALESCE(s.section, '')) AS class_name,
       s.grade,
       s.section,
       COALESCE(s.roll_no, s.roll_number) AS roll_no,
       s.parent_user_id,
       s.status AS student_status
     FROM users u
     LEFT JOIN students s ON s.email = u.email
     ${where.length ? `WHERE ${where.join(' AND ')}` : ''}
     ORDER BY u.created_at DESC, u.id DESC
     LIMIT 100`,
    params,
  );

  return res.json({ users: result.rows.map(userDto) });
});

adminUsersRouter.get('/parents', async (_req, res) => {
  const result = await query(
    `SELECT id, email, first_name, last_name, phone, status
     FROM users
     WHERE role = 'parent'
     ORDER BY first_name NULLS LAST, email`,
    [],
  );
  return res.json({ parents: result.rows });
});

adminUsersRouter.post('/users', async (req, res) => {
  const {
    email,
    password,
    role,
    firstName,
    lastName,
    phone,
    grade,
    section,
    rollNo,
    parentUserId,
  } = req.body;

  if (!email || !password || !role) {
    return res.status(400).json({ error: 'Email, password, and role are required' });
  }
  if (!ROLES.has(role)) {
    return res.status(400).json({ error: 'Unsupported role' });
  }
  if (String(password).length < 8) {
    return res.status(400).json({ error: 'Password must be at least 8 characters' });
  }

  const existing = await query('SELECT id FROM users WHERE email = $1', [normalizeEmail(email)]);
  if (existing.rowCount > 0) {
    return res.status(409).json({ error: 'Email already exists' });
  }

  const user = await createUser({ email, password, role, firstName, lastName, phone });
  let student = null;

  if (role === 'student') {
    const admissionNo = await nextStudentId();
    const fullName = `${firstName ?? ''} ${lastName ?? ''}`.trim() || normalizeEmail(email);
    const studentResult = await query(
      `INSERT INTO students (
         first_name,
         last_name,
         grade,
         section,
         roll_number,
         email,
         phone,
         name,
         class_name,
         roll_no,
         parent_user_id,
         qr_code,
         admission_no,
         status,
         created_at,
         updated_at
       )
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $5, $10, $11, $12, 'active', NOW(), NOW())
       RETURNING id, admission_no, class_name, grade, section, roll_no, parent_user_id, status`,
      [
        firstName ?? 'Student',
        lastName ?? '',
        grade ? Number(grade) : null,
        section ?? null,
        rollNo ?? null,
        normalizeEmail(email),
        phone ?? null,
        fullName,
        className(grade, section),
        parentUserId || null,
        `SSHUB-STUDENT-${admissionNo}`,
        admissionNo,
      ],
    );
    student = studentResult.rows[0];
  }

  await logAudit({
    req,
    targetUserId: user.id,
    targetStudentId: student?.id ?? null,
    action: role === 'student' ? 'student_admitted' : 'user_created',
    category: 'user_creation',
    detail: `Created ${role} account for ${user.email}`,
    metadata: { role, admissionNo: student?.admission_no ?? null },
  });

  return res.status(201).json({
    user: userDto({
      ...user,
      student_id: student?.id ?? null,
      admission_no: student?.admission_no ?? null,
      class_name: student?.class_name ?? null,
      grade: student?.grade ?? null,
      section: student?.section ?? null,
      roll_no: student?.roll_no ?? null,
      parent_user_id: student?.parent_user_id ?? null,
      student_status: student?.status ?? null,
    }),
  });
});

adminUsersRouter.patch('/users/:id/status', async (req, res) => {
  const status = req.body.status?.toString();
  if (!STATUSES.has(status)) {
    return res.status(400).json({ error: 'Status must be active or disabled' });
  }

  const result = await query(
    `UPDATE users
     SET status = $1,
         disabled_at = CASE WHEN $1 = 'disabled' THEN NOW() ELSE NULL END,
         updated_at = NOW()
     WHERE id = $2
     RETURNING id, email, role, first_name, last_name, phone, status, disabled_at, created_at`,
    [status, req.params.id],
  );

  if (result.rowCount === 0) {
    return res.status(404).json({ error: 'User not found' });
  }

  await logAudit({
    req,
    targetUserId: result.rows[0].id,
    action: status === 'disabled' ? 'account_disabled' : 'account_enabled',
    category: 'password_changes',
    detail: `${status === 'disabled' ? 'Disabled' : 'Enabled'} ${result.rows[0].email}`,
  });

  return res.json({ user: userDto(result.rows[0]) });
});

adminUsersRouter.post('/users/:id/reset-password', async (req, res) => {
  const password = req.body.password?.toString();
  if (!password || password.length < 8) {
    return res.status(400).json({ error: 'Password must be at least 8 characters' });
  }

  const hash = await bcrypt.hash(password, SALT_ROUNDS);
  const result = await query(
    `UPDATE users
     SET password_hash = $1, updated_at = NOW()
     WHERE id = $2
     RETURNING id, email, role, first_name, last_name, phone, status, created_at`,
    [hash, req.params.id],
  );

  if (result.rowCount === 0) {
    return res.status(404).json({ error: 'User not found' });
  }

  await logAudit({
    req,
    targetUserId: result.rows[0].id,
    action: 'password_reset',
    category: 'password_changes',
    detail: `Reset password for ${result.rows[0].email}`,
  });

  return res.json({ user: userDto(result.rows[0]) });
});

adminUsersRouter.get('/audit-logs', async (req, res) => {
  const category = req.query.category?.toString();
  const params = [];
  const where = [];
  if (category && category !== 'all') {
    params.push(category);
    where.push(`a.category = $${params.length}`);
  }

  const result = await query(
    `SELECT
       a.id,
       a.action,
       a.category,
       a.detail,
       a.metadata,
       a.created_at,
       actor.email AS actor_email,
       target.email AS target_email,
       s.admission_no
     FROM audit_logs a
     LEFT JOIN users actor ON actor.id = a.actor_user_id
     LEFT JOIN users target ON target.id = a.target_user_id
     LEFT JOIN students s ON s.id = a.target_student_id
     ${where.length ? `WHERE ${where.join(' AND ')}` : ''}
     ORDER BY a.created_at DESC
     LIMIT 50`,
    params,
  );

  return res.json({ logs: result.rows });
});

adminUsersRouter.get('/dashboard', async (_req, res) => {
  const counts = await query(
    `SELECT
       COUNT(*)::int AS users,
       COUNT(*) FILTER (WHERE role = 'student')::int AS students,
       COUNT(*) FILTER (WHERE role = 'teacher')::int AS teachers,
       COUNT(*) FILTER (WHERE role = 'parent')::int AS parents,
       COUNT(*) FILTER (WHERE role = 'admin')::int AS admins,
       COUNT(*) FILTER (WHERE status = 'active')::int AS active,
       COUNT(*) FILTER (WHERE status = 'disabled')::int AS disabled
     FROM users`,
    [],
  );
  const studentRows = await query('SELECT COUNT(*)::int AS count FROM students', []);
  const auditRows = await query('SELECT COUNT(*)::int AS count FROM audit_logs', []);
  const sizeRows = await query(
    `SELECT pg_size_pretty(pg_database_size(current_database())) AS pretty,
            pg_database_size(current_database())::bigint AS bytes`,
    [],
  );
  const classRows = await query(
    `SELECT COALESCE(class_name, 'Class ' || grade || COALESCE(section, 'Unassigned')) AS class_name,
            COUNT(*)::int AS count
     FROM students
     GROUP BY 1
     ORDER BY 1`,
    [],
  );

  return res.json({
    counts: {
      ...counts.rows[0],
      studentRecords: studentRows.rows[0]?.count ?? 0,
      auditLogs: auditRows.rows[0]?.count ?? 0,
    },
    storage: sizeRows.rows[0] ?? { pretty: '0 bytes', bytes: 0 },
    classes: classRows.rows,
  });
});

adminUsersRouter.get('/export/users.csv', async (_req, res) => {
  const result = await query(
    `SELECT
       u.id,
       u.email,
       u.role,
       u.first_name,
       u.last_name,
       u.phone,
       u.status,
       s.admission_no,
       COALESCE(s.class_name, 'Class ' || s.grade || COALESCE(s.section, '')) AS class_name,
       COALESCE(s.roll_no, s.roll_number) AS roll_no,
       u.created_at
     FROM users u
     LEFT JOIN students s ON s.email = u.email
     ORDER BY u.id`,
    [],
  );
  const header = ['id', 'email', 'role', 'first_name', 'last_name', 'phone', 'status', 'admission_no', 'class_name', 'roll_no', 'created_at'];
  const rows = result.rows.map((row) => header.map((key) => csvEscape(row[key])).join(','));
  res.setHeader('Content-Type', 'text/csv; charset=utf-8');
  res.setHeader('Content-Disposition', 'attachment; filename="secure-school-users.csv"');
  return res.send([header.join(','), ...rows].join('\n'));
});
