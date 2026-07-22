import bcrypt from 'bcryptjs';
import dotenv from 'dotenv';
import pg from 'pg';
import { authenticator } from 'otplib';
import path from 'path';
import { fileURLToPath } from 'url';

import { encryptMessage } from '../src/utils/crypto.js';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
dotenv.config({ path: path.join(__dirname, '../.env') });

const pool = new pg.Pool({
  connectionString:
    process.env.DATABASE_URL ||
    'postgres://secure_school_hub:secure_school_hub@localhost:5432/secure_school_hub',
  ssl: process.env.PGSSL === 'true' ? { rejectUnauthorized: false } : false,
});

const PASSWORD = 'password123';
const DEMO_SOURCE = 'demo_seed';
const QUERY_TIMEOUT_MS = 15000;
const requiredTables = [
  'attendance',
  'audit_logs',
  'grades',
  'homework',
  'homework_files',
  'messages',
  'notifications',
  'students',
  'users',
];

const teachers = [
  ['Ananya', 'Rao', 'ananya.rao@secureschoolhub.demo', '9876701001', 'Mathematics'],
  ['Vikram', 'Patel', 'vikram.patel@secureschoolhub.demo', '9876701002', 'Science'],
  ['Priya', 'Menon', 'priya.menon@secureschoolhub.demo', '9876701003', 'English'],
  ['Farhan', 'Khan', 'farhan.khan@secureschoolhub.demo', '9876701004', 'Social Studies'],
  ['Neha', 'Iyer', 'neha.iyer@secureschoolhub.demo', '9876701005', 'Computer Science'],
];

const parents = [
  ['Amit', 'Sharma'], ['Sunita', 'Patel'], ['Rahul', 'Singh'], ['Pooja', 'Gupta'],
  ['Manoj', 'Mehta'], ['Kavita', 'Rao'], ['Sanjay', 'Verma'], ['Farah', 'Khan'],
  ['Ramesh', 'Reddy'], ['Lakshmi', 'Nair'], ['Deepak', 'Jain'], ['Nita', 'Desai'],
  ['George', 'Thomas'], ['Mary', 'Thomas'], ['Suresh', 'Das'], ['Neha', 'Roy'],
  ['Arvind', 'Sen'], ['Meena', 'Acharya'], ['Rohit', 'Kapoor'], ['Salma', 'Ali'],
  ['Mahesh', 'Shah'], ['Kiran', 'Joshi'], ['Harpreet', 'Kaur'], ['Leena', 'Nair'],
  ['Sridhar', 'Iyer'],
].map(([firstName, lastName], index) => [
  firstName,
  lastName,
  `${firstName}.${lastName}.${String(index + 1).padStart(2, '0')}@secureschoolhub.demo`.toLowerCase(),
  `98766010${String(index + 1).padStart(2, '0')}`,
]);

const studentNames = [
  ['Aarav', 'Sharma'], ['Diya', 'Patel'], ['Rohan', 'Singh'], ['Isha', 'Gupta'],
  ['Kabir', 'Mehta'], ['Ananya', 'Rao'], ['Yash', 'Verma'], ['Sana', 'Khan'],
  ['Arjun', 'Reddy'], ['Meera', 'Nair'], ['Devansh', 'Jain'], ['Pooja', 'Desai'],
  ['Aria', 'Kapoor'], ['Neil', 'Thomas'], ['Riya', 'George'], ['Vivaan', 'Das'],
  ['Khushi', 'Singh'], ['Shaurya', 'Roy'], ['Tara', 'Acharya'], ['Kabir', 'Patel'],
  ['Sara', 'Khan'], ['Rohan', 'Raman'], ['Mia', 'Kapoor'], ['Aryan', 'Mehta'],
  ['Naina', 'Sharma'], ['Karan', 'Singh'], ['Simran', 'Kaur'], ['Aditya', 'Sharma'],
  ['Zara', 'Nair'], ['Reyansh', 'Jain'], ['Ishaan', 'Verma'], ['Anika', 'Das'],
  ['Kabir', 'Ali'], ['Riya', 'Sen'], ['Arya', 'Bhatt'], ['Rudra', 'Gupta'],
  ['Anushka', 'Reddy'], ['Kabir', 'Roy'], ['Sara', 'Das'], ['Vihaan', 'Nair'],
  ['Ayaan', 'Khan'], ['Anaya', 'Singh'], ['Reyanshi', 'Patel'], ['Arnav', 'Joshi'],
  ['Kiara', 'Raman'], ['Tanishq', 'Das'], ['Myra', 'Shah'], ['Prisha', 'Jain'],
  ['Aryan', 'Gill'], ['Zoya', 'Iyer'],
];

const subjects = ['Mathematics', 'Science', 'English', 'Social Studies', 'Computer Science'];
const homeworkTopics = [
  ['Fractions revision', 'Complete worksheet 4 and revise solved examples.'],
  ['Plant systems', 'Label the diagram and answer short questions.'],
  ['Reading response', 'Write one paragraph about the assigned chapter.'],
  ['Map practice', 'Mark rivers and state capitals in the workbook.'],
  ['Scratch project', 'Build a simple animation and submit screenshots.'],
  ['Algebra drills', 'Solve questions 1 to 15 from exercise 6B.'],
  ['Lab observation', 'Record observations from the density experiment.'],
  ['Grammar practice', 'Complete the tense correction exercise.'],
  ['Civics notes', 'Summarize the local government chapter.'],
  ['Keyboard skills', 'Practice home-row typing for 15 minutes.'],
];

function slug(value) {
  return value.toLowerCase().replace(/[^a-z0-9]+/g, '.').replace(/^\.+|\.+$/g, '');
}

function rollFor(sequenceNumber) {
  const grade = 8;
  const section = 'A';
  return {
    grade,
    section,
    className: `Class ${String(grade).padStart(2, '0')}${section}`,
    rollNo: `${String(grade).padStart(2, '0')}${section}-${String(sequenceNumber).padStart(2, '0')}`,
    admissionNo: `SSH-${String(grade).padStart(2, '0')}${section}-${String(sequenceNumber).padStart(3, '0')}`,
  };
}

async function timedQuery(client, label, query, params = []) {
  const start = Date.now();
  const timer = setTimeout(() => {
    console.error('QUERY STUCK:', label);
  }, QUERY_TIMEOUT_MS);

  try {
    const result = await client.query(query, params);
    console.log(`${label} completed in ${Date.now() - start}ms`);
    return result;
  } finally {
    clearTimeout(timer);
  }
}

async function verifyRequiredTables(client) {
  const result = await timedQuery(
    client,
    'verify required tables',
    `SELECT table_name
     FROM information_schema.tables
     WHERE table_schema = 'public'
       AND table_name = ANY($1::text[])`,
    [requiredTables],
  );
  const existing = new Set(result.rows.map((row) => row.table_name));
  const missing = requiredTables.filter((table) => !existing.has(table));

  if (missing.length > 0) {
    console.error('Missing tables:', missing.join(', '));
    throw new Error(`Missing required tables: ${missing.join(', ')}`);
  }

  console.log('All required tables exist');
}

async function getAuditActorRequired(client) {
  const result = await timedQuery(
    client,
    'verify audit_logs actor_user_id schema',
    `SELECT is_nullable
     FROM information_schema.columns
     WHERE table_schema = 'public'
       AND table_name = 'audit_logs'
       AND column_name = 'actor_user_id'`,
  );

  if (result.rowCount === 0) {
    throw new Error('audit_logs.actor_user_id column is missing');
  }

  const required = result.rows[0].is_nullable === 'NO';
  console.log(`audit_logs.actor_user_id required: ${required}`);
  return required;
}

async function nextRollSequence(client) {
  const result = await client.query(
    `SELECT roll_number
     FROM students
     WHERE roll_number ~ '^08A-[0-9]+$'
     ORDER BY (regexp_match(roll_number, '^08A-([0-9]+)$'))[1]::int DESC
     LIMIT 1`,
  );
  const latestRoll = result.rows[0]?.roll_number;
  const latestSuffix = latestRoll?.match(/^08A-(\d+)$/)?.[1];
  return latestSuffix ? Number(latestSuffix) + 1 : 1;
}

let studentUserIdColumnExists;
let auditActorUserIdRequired;

async function linkStudentUserIfSupported(client, studentId, userId) {
  if (studentUserIdColumnExists == null) {
    const result = await client.query(
      `SELECT EXISTS (
         SELECT 1
         FROM information_schema.columns
         WHERE table_name = 'students'
           AND column_name = 'user_id'
       ) AS exists`,
    );
    studentUserIdColumnExists = result.rows[0].exists;
  }

  if (studentUserIdColumnExists) {
    await client.query('UPDATE students SET user_id = $1 WHERE id = $2', [userId, studentId]);
  }
}

async function insertUser(client, { firstName, lastName, email, phone, role, passwordHash }) {
  console.log('Checking user:', email);
  const existing = await client.query('SELECT id FROM users WHERE email = $1', [email]);
  if (existing.rowCount > 0) {
    console.log('User exists:', email);
    return { id: existing.rows[0].id, created: false };
  }

  console.log('Inserting user:', email);
  const result = await timedQuery(
    client,
    `users insert: ${email}`,
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
     RETURNING id`,
    [email, passwordHash, role, authenticator.generateSecret(), firstName, lastName, phone],
  );
  console.log('User inserted:', email);

  await audit(client, {
    targetUserId: result.rows[0].id,
    action: 'USER_CREATED',
    category: 'user_creation',
    detail: `Demo ${role} user created: ${email}`,
    metadata: { source: DEMO_SOURCE, role },
  });

  return { id: result.rows[0].id, created: true };
}

async function audit(client, {
  actorUserId = null,
  targetUserId = null,
  targetStudentId = null,
  action,
  category,
  detail,
  metadata = {},
}) {
  console.log('Audit insert:', action);
  const effectiveActorUserId = actorUserId ?? (auditActorUserIdRequired ? targetUserId : null);

  await timedQuery(
    client,
    `audit_logs insert: ${action}`,
    `INSERT INTO audit_logs (
       actor_user_id,
       target_user_id,
       target_student_id,
       action,
       category,
       detail,
       metadata,
       created_at
     )
     VALUES ($1, $2, $3, $4, $5, $6, $7::jsonb, NOW())`,
    [
      effectiveActorUserId,
      targetUserId,
      targetStudentId,
      action,
      category,
      detail,
      JSON.stringify(metadata),
    ],
  );
}

async function seedPeople(client) {
  const passwordHash = await bcrypt.hash(PASSWORD, 10);
  const stats = { teachers: 0, parents: 0, students: 0 };
  const teacherIds = [];
  const parentIds = [];
  const studentRows = [];

  console.log('Starting teacher creation');
  for (const [firstName, lastName, email, phone] of teachers) {
    console.log('Teacher:', email);
    const result = await insertUser(client, {
      firstName,
      lastName,
      email,
      phone,
      role: 'teacher',
      passwordHash,
    });
    teacherIds.push(result.id);
    if (result.created) stats.teachers += 1;
  }

  console.log('Starting parent creation');
  for (const [firstName, lastName, email, phone] of parents) {
    console.log('Parent:', email);
    const result = await insertUser(client, {
      firstName,
      lastName,
      email,
      phone,
      role: 'parent',
      passwordHash,
    });
    parentIds.push(result.id);
    if (result.created) stats.parents += 1;
  }

  let rollSequence = await nextRollSequence(client);

  console.log('Starting student creation');
  for (let i = 0; i < studentNames.length; i += 1) {
    const [firstName, lastName] = studentNames[i];
    const parentUserId = parentIds[i % parentIds.length];
    const email = `${slug(firstName)}.${slug(lastName)}.${String(i + 1).padStart(2, '0')}@student.secureschoolhub.demo`;
    console.log('Student:', email);
    const existingByEmail = await client.query(
      `SELECT
         id,
         qr_code,
         admission_no,
         COALESCE(roll_number, roll_no) AS roll_number,
         COALESCE(class_name, 'Class ' || grade || COALESCE(section, '')) AS class_name
       FROM students
       WHERE email = $1
       LIMIT 1`,
      [email],
    );
    const existingStudent = existingByEmail.rows[0] ?? null;
    const roll = existingStudent
      ? {
          grade: 8,
          section: 'A',
          className: existingStudent.class_name ?? 'Class 08A',
          rollNo: existingStudent.roll_number,
          admissionNo: existingStudent.admission_no,
        }
      : rollFor(rollSequence);
    const { grade, section, className, rollNo, admissionNo } = roll;
    const phone = `98765010${String(i + 1).padStart(2, '0')}`;

    const user = await insertUser(client, {
      firstName,
      lastName,
      email,
      phone,
      role: 'student',
      passwordHash,
    });

    const existing = existingStudent
      ? { rowCount: 1, rows: [existingStudent] }
      : await client.query(
          'SELECT id, qr_code FROM students WHERE admission_no = $1 OR roll_number = $2 LIMIT 1',
          [admissionNo, rollNo],
        );

    let studentId;
    let qrCode;
    if (existing.rowCount > 0) {
      studentId = existing.rows[0].id;
      qrCode = existing.rows[0].qr_code;
    } else {
      qrCode = `SSHUB-STUDENT-${admissionNo}`;
      const student = await timedQuery(
        client,
        `students insert: ${email}`,
        `INSERT INTO students (
           first_name,
           last_name,
           grade,
           section,
           roll_number,
           email,
           phone,
           address,
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
         VALUES ($1, $2, $3, $4, $5, $6, $7, 'Mumbai', $8, $9, $5, $10, $11, $12, 'active', NOW(), NOW())
         RETURNING id`,
        [
          firstName,
          lastName,
          grade,
          section,
          rollNo,
          email,
          phone,
          `${firstName} ${lastName}`,
          className,
          parentUserId,
          qrCode,
          admissionNo,
        ],
      );
      studentId = student.rows[0].id;
      rollSequence += 1;
      stats.students += 1;
      await audit(client, {
        targetUserId: user.id,
        targetStudentId: studentId,
        action: 'STUDENT_CREATED',
        category: 'user_creation',
        detail: `Demo student created: ${firstName} ${lastName} (${admissionNo})`,
        metadata: { source: DEMO_SOURCE, admissionNo, className, rollNo, linkedUserId: user.id },
      });
    }

    await linkStudentUserIfSupported(client, studentId, user.id);

    studentRows.push({
      id: studentId,
      userId: user.id,
      name: `${firstName} ${lastName}`,
      admissionNo,
      className,
      rollNo,
      parentUserId,
      qrCode,
    });
  }

  return { stats, teacherIds, parentIds, studentRows };
}

async function seedAttendance(client, students) {
  const existing = await client.query(
    "SELECT COUNT(*)::int AS count FROM attendance WHERE qr_data LIKE '%\"source\":\"demo_seed\"%'",
  );
  if (existing.rows[0].count > 0) return 0;

  const userIds = [];
  const studentIds = [];
  const qrDataRows = [];
  const markedAtRows = [];
  const now = new Date();
  for (let dayOffset = 1; dayOffset <= 30; dayOffset += 1) {
    const day = new Date(now);
    day.setDate(now.getDate() - dayOffset);
    day.setHours(8, 15, 0, 0);

    for (let i = 0; i < students.length; i += 1) {
      const student = students[i];
      const markedAt = new Date(day);
      markedAt.setMinutes(15 + ((i * 7 + dayOffset) % 95));
      const present = Math.random() < 0.82;
      const payload = {
        source: DEMO_SOURCE,
        type: 'attendance_demo',
        status: present ? 'present' : 'absent',
        studentId: student.id,
        studentUserId: student.userId,
        admissionNo: student.admissionNo,
        qrCode: student.qrCode,
      };
      userIds.push(student.userId);
      studentIds.push(student.id);
      qrDataRows.push(JSON.stringify(payload));
      markedAtRows.push(markedAt);
    }
  }

  await timedQuery(
    client,
    `attendance insert: ${qrDataRows.length} demo rows`,
    `INSERT INTO attendance (user_id, student_id, qr_data, marked_at)
     SELECT *
     FROM unnest($1::int[], $2::int[], $3::text[], $4::timestamptz[])`,
    [userIds, studentIds, qrDataRows, markedAtRows],
  );

  return qrDataRows.length;
}

async function seedHomework(client, teacherIds) {
  const existing = await client.query(
    "SELECT COUNT(*)::int AS count FROM homework WHERE description LIKE '%[demo_seed]%'",
  );
  if (existing.rows[0].count > 0) return 0;

  const teacherIdRows = [];
  const titleRows = [];
  const descriptionRows = [];
  const dayOffsetRows = [];
  for (let i = 0; i < homeworkTopics.length; i += 1) {
    const [title, description] = homeworkTopics[i];
    teacherIdRows.push(teacherIds[i % teacherIds.length]);
    titleRows.push(title);
    descriptionRows.push(`${description} [demo_seed]`);
    dayOffsetRows.push(i + 1);
  }

  await timedQuery(
    client,
    `homework insert: ${titleRows.length} demo rows`,
    `INSERT INTO homework (teacher_id, title, description, created_at)
     SELECT teacher_id, title, description, NOW() - (day_offset * INTERVAL '1 day')
     FROM unnest($1::int[], $2::text[], $3::text[], $4::int[])
       AS rows(teacher_id, title, description, day_offset)`,
    [teacherIdRows, titleRows, descriptionRows, dayOffsetRows],
  );

  return titleRows.length;
}

async function seedNotifications(client, parentIds) {
  const existing = await client.query(
    "SELECT COUNT(*)::int AS count FROM notifications WHERE type LIKE 'demo_%'",
  );
  if (existing.rows[0].count > 0) return 0;

  const templates = [
    ['Attendance update', 'Your child attendance summary is available.', 'demo_attendance'],
    ['Fee reminder', 'Term fee reminder has been generated.', 'demo_fee'],
    ['Homework assigned', 'New homework has been posted by the class teacher.', 'demo_homework'],
    ['PTM schedule', 'Parent teacher meeting slots open this Friday.', 'demo_notice'],
  ];

  const userIdRows = [];
  const titleRows = [];
  const bodyRows = [];
  const typeRows = [];
  const dayOffsetRows = [];
  for (let i = 0; i < parentIds.length; i += 1) {
    for (let j = 0; j < 2; j += 1) {
      const template = templates[(i + j) % templates.length];
      userIdRows.push(parentIds[i]);
      titleRows.push(template[0]);
      bodyRows.push(template[1]);
      typeRows.push(template[2]);
      dayOffsetRows.push((i + j) % 14);
    }
  }

  await timedQuery(
    client,
    `notifications insert: ${titleRows.length} demo rows`,
    `INSERT INTO notifications (user_id, title, body, type, created_at)
     SELECT user_id, title, body, type, NOW() - (day_offset * INTERVAL '1 day')
     FROM unnest($1::int[], $2::text[], $3::text[], $4::text[], $5::int[])
       AS rows(user_id, title, body, type, day_offset)`,
    [userIdRows, titleRows, bodyRows, typeRows, dayOffsetRows],
  );

  return titleRows.length;
}

async function seedMessages(client, teacherIds, parentIds) {
  const generated = await client.query(
    `SELECT COUNT(*)::int AS count
     FROM audit_logs
     WHERE action = 'DEMO_DATA_GENERATED'
       AND metadata->>'source' = $1`,
    [DEMO_SOURCE],
  );
  if (generated.rows[0].count > 0) return 0;

  const samples = [
    'demo_seed_marker: Please review the weekly progress note.',
    'demo_seed_marker: Thank you, we will support the reading practice at home.',
    'demo_seed_marker: The project submission was received successfully.',
    'demo_seed_marker: Could we schedule a short call after school tomorrow?',
  ];

  let created = 0;
  for (let i = 0; i < 20; i += 1) {
    const senderId = i % 2 === 0
      ? teacherIds[i % teacherIds.length]
      : parentIds[i % parentIds.length];
    await client.query(
      `INSERT INTO messages (sender_id, body_enc, created_at)
       VALUES ($1, $2, NOW() - ($3::int * INTERVAL '1 hour'))`,
      [senderId, encryptMessage(samples[i % samples.length]), i + 1],
    );
    created += 1;
  }
  return created;
}

async function seedGrades(client, students) {
  const existing = await client.query(
    `SELECT COUNT(*)::int AS count
     FROM grades
     WHERE term = 'Demo Term 1'`,
  );
  if (existing.rows[0].count > 0) return 0;

  const studentIdRows = [];
  const subjectRows = [];
  const scoreRows = [];
  const maxScoreRows = [];
  const termRows = [];
  for (let i = 0; i < students.length; i += 1) {
    for (let s = 0; s < subjects.length; s += 1) {
      const score = 68 + ((i * 5 + s * 7) % 30);
      studentIdRows.push(students[i].userId);
      subjectRows.push(subjects[s]);
      scoreRows.push(score);
      maxScoreRows.push(100);
      termRows.push('Demo Term 1');
    }
  }

  await timedQuery(
    client,
    `grades insert: ${subjectRows.length} demo rows`,
    `INSERT INTO grades (student_id, subject, score, max_score, term)
     SELECT *
     FROM unnest($1::int[], $2::text[], $3::numeric[], $4::numeric[], $5::text[])`,
    [studentIdRows, subjectRows, scoreRows, maxScoreRows, termRows],
  );

  return subjectRows.length;
}

async function main() {
  console.log('SEED STARTED');
  const client = await pool.connect();
  const totals = {
    teachers: 0,
    parents: 0,
    students: 0,
    attendance: 0,
    homework: 0,
    notifications: 0,
  };

  try {
    await verifyRequiredTables(client);
    auditActorUserIdRequired = await getAuditActorRequired(client);
    console.log('BEGIN TRANSACTION');
    await client.query('BEGIN');
    console.log('STARTING PEOPLE');
    const seeded = await seedPeople(client);
    console.log('PEOPLE SEEDED');
    totals.teachers = seeded.stats.teachers;
    totals.parents = seeded.stats.parents;
    totals.students = seeded.stats.students;
    console.log('STARTING ATTENDANCE');
    totals.attendance = await seedAttendance(client, seeded.studentRows);
    console.log('ATTENDANCE SEEDED');
    console.log('STARTING HOMEWORK');
    totals.homework = await seedHomework(client, seeded.teacherIds);
    console.log('HOMEWORK SEEDED');
    console.log('STARTING NOTIFICATIONS');
    totals.notifications = await seedNotifications(client, seeded.parentIds);
    console.log('NOTIFICATIONS SEEDED');
    console.log('STARTING MESSAGES');
    await seedMessages(client, seeded.teacherIds, seeded.parentIds);
    console.log('MESSAGES SEEDED');
    console.log('STARTING GRADES');
    await seedGrades(client, seeded.studentRows);
    console.log('GRADES SEEDED');
    const generatedAudit = await client.query(
      `SELECT COUNT(*)::int AS count
       FROM audit_logs
       WHERE action = 'DEMO_DATA_GENERATED'
         AND metadata->>'source' = $1`,
      [DEMO_SOURCE],
    );
    if (generatedAudit.rows[0].count === 0) {
      await audit(client, {
        action: 'DEMO_DATA_GENERATED',
        category: 'user_creation',
        detail: 'Demo data seeder completed',
        metadata: { source: DEMO_SOURCE, totals },
      });
    }
    console.log('COMMITTING');
    await client.query('COMMIT');
    console.log('COMPLETED');
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
    await pool.end();
  }

  console.log(`Teachers Created: ${totals.teachers}`);
  console.log(`Parents Created: ${totals.parents}`);
  console.log(`Students Created: ${totals.students}`);
  console.log(`Attendance Records: ${totals.attendance}`);
  console.log(`Homework Records: ${totals.homework}`);
  console.log(`Notifications: ${totals.notifications}`);
}

main().catch((error) => {
  console.error('Demo data seeding failed:', error);
  process.exit(1);
});
