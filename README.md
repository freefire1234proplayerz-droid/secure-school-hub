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
