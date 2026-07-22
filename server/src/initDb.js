import bcrypt from 'bcryptjs';
import { authenticator } from 'otplib';

import { query } from './db.js';

const password = 'password123';

const demoUsers = [
  { email: 'admin@school.com', role: 'admin', firstName: 'Secure', lastName: 'Admin' },
  { email: 'teacher@school.com', role: 'teacher', firstName: 'Demo', lastName: 'Teacher' },
  { email: 'parent@school.com', role: 'parent', firstName: 'Demo', lastName: 'Parent' },
];

const demoStudents = [
  {
    firstName: 'Aarav',
    lastName: 'Sharma',
    name: 'Aarav Sharma',
    className: 'Class 8A',
    rollNo: '08A-01',
    qrCode: 'SSHUB-STUDENT-08A-001',
  },
  {
    firstName: 'Isha',
    lastName: 'Mehta',
    name: 'Isha Mehta',
    className: 'Class 8A',
    rollNo: '08A-02',
    qrCode: 'SSHUB-STUDENT-08A-002',
  },
  {
    firstName: 'Kabir',
    lastName: 'Rao',
    name: 'Kabir Rao',
    className: 'Class 8A',
    rollNo: '08A-03',
    qrCode: 'SSHUB-STUDENT-08A-003',
  },
  {
    firstName: 'Meera',
    lastName: 'Iyer',
    name: 'Meera Iyer',
    className: 'Class 8A',
    rollNo: '08A-04',
    qrCode: 'SSHUB-STUDENT-08A-004',
  },
];

export async function ensureDatabaseReady() {
  await query(`
    CREATE TABLE IF NOT EXISTS users (
      id SERIAL PRIMARY KEY,
      email TEXT UNIQUE NOT NULL,
      password_hash TEXT NOT NULL,
      role TEXT NOT NULL,
      totp_secret TEXT NOT NULL
    );
  `);

  await query('ALTER TABLE users DROP CONSTRAINT IF EXISTS users_role_check;', []);
  await query('ALTER TABLE users ADD COLUMN IF NOT EXISTS first_name TEXT;', []);
  await query('ALTER TABLE users ADD COLUMN IF NOT EXISTS last_name TEXT;', []);
  await query('ALTER TABLE users ADD COLUMN IF NOT EXISTS phone TEXT;', []);
  await query("ALTER TABLE users ADD COLUMN IF NOT EXISTS status TEXT NOT NULL DEFAULT 'active';", []);
  await query('ALTER TABLE users ADD COLUMN IF NOT EXISTS disabled_at TIMESTAMP WITH TIME ZONE;', []);
  await query('ALTER TABLE users ADD COLUMN IF NOT EXISTS created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW();', []);
  await query('ALTER TABLE users ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW();', []);
  await query(
    "UPDATE users SET status = 'active' WHERE status IS NULL OR status = '';",
    [],
  );

  await query(`
    CREATE TABLE IF NOT EXISTS students (
      id SERIAL PRIMARY KEY,
      first_name TEXT NOT NULL,
      last_name TEXT NOT NULL,
      grade INTEGER,
      section TEXT,
      roll_number TEXT UNIQUE,
      email TEXT UNIQUE,
      phone TEXT,
      address TEXT,
      name TEXT,
      class_name TEXT,
      roll_no TEXT,
      parent_user_id INTEGER REFERENCES users(id),
      qr_code TEXT UNIQUE,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );
  `);

  const studentColumns = [
    ['first_name', 'TEXT'],
    ['last_name', 'TEXT'],
    ['grade', 'INTEGER'],
    ['section', 'TEXT'],
    ['roll_number', 'TEXT'],
    ['name', 'TEXT'],
    ['class_name', 'TEXT'],
    ['roll_no', 'TEXT'],
    ['parent_user_id', 'INTEGER REFERENCES users(id)'],
    ['qr_code', 'TEXT'],
    ['admission_no', 'TEXT'],
    ['status', "TEXT NOT NULL DEFAULT 'active'"],
  ];

  for (const [name, type] of studentColumns) {
    await query(`ALTER TABLE students ADD COLUMN IF NOT EXISTS ${name} ${type};`, []);
  }

  await query(
    'CREATE UNIQUE INDEX IF NOT EXISTS students_qr_code_unique ON students(qr_code);',
    [],
  );
  await query(
    'CREATE UNIQUE INDEX IF NOT EXISTS students_admission_no_unique ON students(admission_no);',
    [],
  );

  await query(`
    CREATE TABLE IF NOT EXISTS attendance (
      id SERIAL PRIMARY KEY,
      user_id INTEGER REFERENCES users(id),
      student_id INTEGER REFERENCES students(id),
      qr_data TEXT NOT NULL,
      marked_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
    );
  `);
  await query('ALTER TABLE attendance ADD COLUMN IF NOT EXISTS student_id INTEGER REFERENCES students(id);', []);

  await query(`
    CREATE TABLE IF NOT EXISTS audit_logs (
      id SERIAL PRIMARY KEY,
      actor_user_id INTEGER REFERENCES users(id),
      target_user_id INTEGER REFERENCES users(id),
      target_student_id INTEGER REFERENCES students(id),
      action TEXT NOT NULL,
      category TEXT NOT NULL,
      detail TEXT,
      metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
      ip_address TEXT,
      user_agent TEXT,
      created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
    );
  `);

  await query(`
    CREATE TABLE IF NOT EXISTS homework (
      id SERIAL PRIMARY KEY,
      teacher_id INTEGER REFERENCES users(id),
      title TEXT NOT NULL,
      description TEXT,
      created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
    );
  `);

  await query(`
    CREATE TABLE IF NOT EXISTS grades (
      id SERIAL PRIMARY KEY,
      student_id INTEGER REFERENCES users(id),
      subject TEXT NOT NULL,
      score NUMERIC NOT NULL,
      max_score NUMERIC NOT NULL,
      term TEXT NOT NULL
    );
  `);

  await query(`
    CREATE TABLE IF NOT EXISTS messages (
      id SERIAL PRIMARY KEY,
      sender_id INTEGER REFERENCES users(id),
      body_enc TEXT NOT NULL,
      created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
    );
  `);

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

  const hash = await bcrypt.hash(password, 10);

  for (const user of demoUsers) {
    await query(
      `INSERT INTO users (email, password_hash, role, totp_secret)
       VALUES ($1, $2, $3, $4)
       ON CONFLICT (email)
       DO UPDATE SET password_hash = $2, role = $3, status = 'active'`,
      [user.email, hash, user.role, authenticator.generateSecret()],
    );
    await query(
      `UPDATE users
       SET first_name = COALESCE(first_name, $2),
           last_name = COALESCE(last_name, $3)
       WHERE email = $1`,
      [user.email, user.firstName, user.lastName],
    );
  }

  const parentResult = await query(
    "SELECT id FROM users WHERE email = 'parent@school.com' LIMIT 1",
    [],
  );
  const teacherResult = await query(
    "SELECT id FROM users WHERE email = 'teacher@school.com' LIMIT 1",
    [],
  );
  const parentUserId = parentResult.rows[0]?.id ?? null;
  const teacherUserId = teacherResult.rows[0]?.id ?? null;

  for (const student of demoStudents) {
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
         qr_code,
         admission_no,
         status
       )
       VALUES ($1, $2, 8, 'A', $3, $4, $5, $6, $7, $8, $9, 'active')
       ON CONFLICT (qr_code)
       DO UPDATE SET
         first_name = EXCLUDED.first_name,
         last_name = EXCLUDED.last_name,
         grade = EXCLUDED.grade,
         section = EXCLUDED.section,
         roll_number = EXCLUDED.roll_number,
         name = EXCLUDED.name,
         class_name = EXCLUDED.class_name,
         roll_no = EXCLUDED.roll_no,
         parent_user_id = COALESCE(students.parent_user_id, EXCLUDED.parent_user_id),
         admission_no = COALESCE(students.admission_no, EXCLUDED.admission_no),
         status = COALESCE(students.status, 'active')`,
      [
        student.firstName,
        student.lastName,
        student.rollNo,
        student.name,
        student.className,
        student.rollNo,
        parentUserId,
        student.qrCode,
        student.qrCode.replace('SSHUB-STUDENT-', 'SSH-'),
      ],
    );
  }

  if (teacherUserId) {
    await query(
      `INSERT INTO homework (teacher_id, title, description, created_at)
       SELECT $1, 'Math practice', 'Solve exercise 5 from chapter 2', NOW()
       WHERE NOT EXISTS (SELECT 1 FROM homework WHERE title = 'Math practice')`,
      [teacherUserId],
    );
    await query(
      `INSERT INTO homework (teacher_id, title, description, created_at)
       SELECT $1, 'Science worksheet', 'Revise chapter 4 and answer worksheet questions', NOW()
       WHERE NOT EXISTS (SELECT 1 FROM homework WHERE title = 'Science worksheet')`,
      [teacherUserId],
    );
  }

  if (parentUserId) {
    const gradeRows = [
      ['Mathematics', 91, 100, 'Term 2'],
      ['Science', 84, 100, 'Term 2'],
      ['English', 88, 100, 'Term 2'],
      ['Social Studies', 81, 100, 'Term 2'],
    ];

    for (const [subject, score, maxScore, term] of gradeRows) {
      await query(
        `INSERT INTO grades (student_id, subject, score, max_score, term)
         SELECT $1, $2, $3, $4, $5
         WHERE NOT EXISTS (
           SELECT 1 FROM grades WHERE student_id = $1 AND subject = $2 AND term = $5
         )`,
        [parentUserId, subject, score, maxScore, term],
      );
    }
  }
}
