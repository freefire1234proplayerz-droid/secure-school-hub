/**
 * Seeds one teacher and one parent for local testing.
 * Run from project root: node server/scripts/seed-user.js
 * Requires: DATABASE_URL in server/.env (use postgres://secure_school_hub:secure_school_hub@localhost:5432/secure_school_hub if Postgres is on host)
 */
import pg from 'pg';
import bcrypt from 'bcryptjs';
import { authenticator } from 'otplib';
import dotenv from 'dotenv';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
dotenv.config({ path: path.join(__dirname, '../.env') });

const pool = new pg.Pool({
  connectionString: process.env.DATABASE_URL || 'postgres://secure_school_hub:secure_school_hub@localhost:5432/secure_school_hub',
});

const OTP_STEP_SECONDS = 120;
authenticator.options = {
  step: OTP_STEP_SECONDS,
};

const password = 'password123';

async function main() {
  const hash = await bcrypt.hash(password, 10);
  const adminSecret = authenticator.generateSecret();
  const teacherSecret = authenticator.generateSecret();
  const parentSecret = authenticator.generateSecret();

  await pool.query(`
    CREATE TABLE IF NOT EXISTS users (
      id SERIAL PRIMARY KEY,
      email TEXT UNIQUE NOT NULL,
      password_hash TEXT NOT NULL,
      role TEXT NOT NULL,
      totp_secret TEXT NOT NULL
    );
  `);
  await pool.query('ALTER TABLE users DROP CONSTRAINT IF EXISTS users_role_check;');

  await pool.query(
    `INSERT INTO users (email, password_hash, role, totp_secret)
     VALUES ($1, $2, 'admin', $3)
     ON CONFLICT (email) DO UPDATE SET password_hash = $2, role = 'admin', totp_secret = $3`,
    ['admin@school.com', hash, adminSecret],
  );
  await pool.query(
    `INSERT INTO users (email, password_hash, role, totp_secret)
     VALUES ($1, $2, 'teacher', $3)
     ON CONFLICT (email) DO UPDATE SET password_hash = $2, role = 'teacher', totp_secret = $3`,
    ['teacher@school.com', hash, teacherSecret],
  );
  await pool.query(
    `INSERT INTO users (email, password_hash, role, totp_secret)
     VALUES ($1, $2, 'parent', $3)
     ON CONFLICT (email) DO UPDATE SET password_hash = $2, role = 'parent', totp_secret = $3`,
    ['parent@school.com', hash, parentSecret],
  );

  const adminOtp = authenticator.generate(adminSecret);
  const teacherOtp = authenticator.generate(teacherSecret);
  const parentOtp = authenticator.generate(parentSecret);

  console.log('Seeded users (password for all: password123)');
  console.log('  Admin:   admin@school.com    → current OTP:', adminOtp);
  console.log('  Teacher: teacher@school.com  → current OTP:', teacherOtp);
  console.log('  Parent:  parent@school.com   → current OTP:', parentOtp);
  console.log('(OTP changes every 2 minutes; use the one shown in the app after you tap Send OTP.)');
  await pool.end();
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
