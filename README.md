# 🎓 SecureSchoolHub

<p align="center">

# 🎓 SecureSchoolHub

**AI Powered School ERP built with Flutter, Node.js, PostgreSQL & Google Gemini AI**

A modern school management platform designed for educational institutions to simplify administration, improve communication and enhance student learning using Artificial Intelligence.

---

## ✨ Features

### 👨‍💼 Admin

- Dashboard Analytics
- Student Management
- Parent Management
- Teacher Management
- User Management
- Audit Logs
- Notifications

---

### 👩‍🏫 Teacher

- Attendance Management
- Homework Management
- Homework File Upload
- Grade Management
- Student Performance
- Notifications

---

### 👨‍👩‍👧 Parent

- Attendance Tracking
- Homework Updates
- Grade Reports
- Notifications
- AI Study Assistant

---

### 🎓 Student

- Homework
- Attendance
- Grades
- Notifications
- AI Tutor

---

# 🤖 AI Study Buddy

Powered by Google Gemini AI

Features:

- Homework Assistance
- Programming Help
- Mathematics Solutions
- Science Explanations
- Learning Support
- Study Planning

---

# 🔒 Security

- JWT Authentication
- Password Hashing
- Role Based Access
- Secure REST APIs
- Audit Logging
- Environment Variables

---

# 💳 Payment Gateway

- Razorpay Integration
- Fee Collection
- Payment Tracking

---

# 🔔 Notifications

- Firebase Cloud Messaging
- Homework Alerts
- Attendance Updates
- School Announcements

---

# 🛠 Tech Stack

### Frontend

- Flutter
- Dart
- Material Design 3
- Hive

### Backend

- Node.js
- Express.js
- PostgreSQL
- JWT
- bcrypt

### AI

- Google Gemini AI

### Services

- Firebase
- Razorpay
- Docker

---

# 📂 Project Structure

```
lib/
server/
assets/
web/
macos/
```

---

# 🚀 Installation

Clone Repository

```bash
git clone https://github.com/freefire1234proplayerz-droid/secure-school-hub.git
```

Flutter

```bash
flutter pub get

flutter run
```

Backend

```bash
cd server

npm install

cp .env.example .env

npm start
```

Seed Demo Data

```bash
npm run seed
```

---

# 🏗 Architecture

```
Flutter App
     │
 REST API
     │
Node.js
     │
Google Gemini AI
     │
PostgreSQL
```

---

# 🚀 Future Enhancements

- Face Recognition Attendance
- Biometric Attendance
- AI Report Card Analysis
- Voice Assistant
- Personalized Learning
- Multi School Support

---

# 📷 Screenshots

Coming Soon...

---

# 👨‍💻 Developer

**Avanish Kamble**

Bachelor of Engineering (Information Technology)

Mumbai, India

GitHub

https://github.com/freefire1234proplayerz-droid

---

⭐ If you like this project, consider giving it a Star.

---

## Backend Configuration

Copy `server/.env.example` to `server/.env` and configure the required values:

```bash
cd server
cp .env.example .env
```

Important variables include `DATABASE_URL`, `JWT_SECRET`, `MESSAGE_ENC_KEY`, and the Razorpay credentials `RAZORPAY_KEY_ID` / `RAZORPAY_KEY_SECRET`. Use strong, unique secrets and never commit `.env` files or credentials.

## Local Development and Health Check

Start the backend dependencies with Docker Compose if you are using the included Docker setup:

```bash
docker compose up -d --build
```

The API listens on port 4000 by default. Check its health with:

```bash
curl -i http://localhost:4000/api/health
```

For local Flutter development, point the app at the local API using the compile-time base URL:

```bash
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:4000/api
```

Configure Firebase for your target platform before relying on Firebase Cloud Messaging.

## Deployment Notes

For Linux deployment, configure the database and API environment securely before exposing the service. Use HTTPS through a properly configured reverse proxy, restrict inbound ports with a firewall, and rotate any default or previously exposed credentials. Review the supplied Docker Compose and deployment scripts before running them in a production environment.

## Security Notes

- Chat messages use server-side AES encryption via `MESSAGE_ENC_KEY`; this is not end-to-end encryption because the server can decrypt messages. True E2E encryption requires client-held keys and no server-side decryption.
- Use unique strong values for all secrets in `.env`; never commit real secrets.
- Restrict network-scanning targets to authorized internal systems only.
- Back up encryption keys securely. Rotating `MESSAGE_ENC_KEY` can make existing encrypted messages unreadable unless you migrate them.

---

## Detailed Project Structure

- `pubspec.yaml` – Flutter dependencies.
- `lib/` – Flutter app:
  - `main.dart` – app entrypoint, localization, theme, providers.
  - `l10n/app_localizations.dart` – simple Hindi/English strings.
  - `providers/locale_provider.dart` – language toggle.
  - `screens/login_screen.dart` – JWT + 2FA login flow (clean professional UI).
  - `screens/teacher_dashboard.dart` – QR attendance, homework, fee reminders, quick actions.
  - `screens/parent_dashboard.dart` – grades, attendance, fee proof upload, AI tutor access.
  - `screens/admin/admin_dashboard.dart` – user management, analytics, security center, communications.
  - `screens/student/ai_tutor_screen.dart` – AI-powered tutoring with Google Gemini.
  - `services/local_db.dart` – Hive boxes for auth + offline cache.
  - `services/api_service.dart` – Dio API client with offline pending-actions pattern.
  - `services/auth_service.dart` – login + OTP verification + session handling.
  - `services/frontend_experience_service.dart` – offline queue, connectivity, preferences.
  - `theme/` – professional design system (colors, typography, spacing, shadows, glass cards).
  - `widgets/` – reusable UI components (glass cards, buttons, charts, attendance, chat, shells).
- `server/` – Node backend:
  - `package.json`, `Dockerfile`, `.env.example`.
  - `src/index.js` – Express app + route wiring, CSP, CORS, rate limiting, error handling.
  - `src/db.js` – PostgreSQL pool helper.
  - `src/middleware/auth.js` – JWT auth middleware with role-based access.
  - `src/middleware/validate.js` – express-validator input validation for all routes.
  - `src/utils/crypto.js` – AES encryption helpers for chat messages (fails fast if key not set).
  - `src/utils/audit.js` – audit logging for security-relevant actions.
  - `src/utils/notify.js` – notification creation for parents/teachers.
  - `src/services/aiTutorService.js` – Google Gemini integration with retries/fallback.
  - `src/initDb.js` – schema creation + demo data seeding (preserves existing passwords in production).
  - `src/routes/*.js` – modular routes for auth, attendance, homework, fees, grades, chat, security, dashboard, admin, AI.
- `docker-compose.yml` – services for `db` (Postgres) and `server`.
- `scripts/setup_ubuntu_secure_school_hub.sh` – Ubuntu setup helper (UFW, Docker, Nginx, Certbot, WireGuard).

---

## Current Database Schema

Run this SQL against the Postgres instance (e.g. via `psql` in the `db` container). The `initDb.js` script handles this automatically on server startup.

```sql
CREATE TABLE IF NOT EXISTS users (
  id SERIAL PRIMARY KEY,
  email TEXT UNIQUE NOT NULL,
  password_hash TEXT NOT NULL,
  role TEXT NOT NULL CHECK (role IN ('student', 'teacher', 'parent', 'admin')),
  totp_secret TEXT NOT NULL,
  first_name TEXT,
  last_name TEXT,
  phone TEXT,
  status TEXT NOT NULL DEFAULT 'active',
  disabled_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

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
  admission_no TEXT UNIQUE,
  status TEXT NOT NULL DEFAULT 'active',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS attendance (
  id SERIAL PRIMARY KEY,
  user_id INTEGER REFERENCES users(id),
  student_id INTEGER REFERENCES students(id),
  qr_data TEXT NOT NULL,
  marked_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

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

CREATE TABLE IF NOT EXISTS homework (
  id SERIAL PRIMARY KEY,
  teacher_id INTEGER REFERENCES users(id),
  title TEXT NOT NULL,
  description TEXT,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS homework_files (
  id SERIAL PRIMARY KEY,
  homework_id INTEGER REFERENCES homework(id) ON DELETE SET NULL,
  teacher_id INTEGER REFERENCES users(id),
  file_name TEXT NOT NULL,
  file_size BIGINT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS grades (
  id SERIAL PRIMARY KEY,
  student_id INTEGER REFERENCES students(id),
  subject TEXT NOT NULL,
  score NUMERIC NOT NULL,
  max_score NUMERIC NOT NULL,
  term TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS fee_records (
  id SERIAL PRIMARY KEY,
  student_id INTEGER REFERENCES students(id),
  amount NUMERIC NOT NULL,
  currency TEXT NOT NULL DEFAULT 'INR',
  status TEXT NOT NULL DEFAULT 'pending',
  razorpay_order_id TEXT,
  razorpay_payment_id TEXT,
  due_date DATE,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS fee_files (
  id SERIAL PRIMARY KEY,
  user_id INTEGER REFERENCES users(id),
  role TEXT NOT NULL,
  file_name TEXT NOT NULL,
  file_size BIGINT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS messages (
  id SERIAL PRIMARY KEY,
  sender_id INTEGER REFERENCES users(id),
  body_enc TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS notifications (
  id SERIAL PRIMARY KEY,
  user_id INTEGER REFERENCES users(id),
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  type TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  read_at TIMESTAMP WITH TIME ZONE
);
```

> **Note**: Chat messages are stored AES-encrypted via `MESSAGE_ENC_KEY`. For true E2E you would manage per-device keys and avoid server-side decryption; this repo uses server-side encryption for simplicity. The `MESSAGE_ENC_KEY` must be set to a strong random value (32+ bytes base64) in production.
