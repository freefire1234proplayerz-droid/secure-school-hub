# SecureSchoolHub Boss Demo Deployment

## Local Demo

Start backend and database:

```bash
cd /Users/avanishkamble/school
docker compose up -d --build
```

Run the Flutter web app:

```bash
flutter run -d web-server --web-hostname=localhost --web-port=3000 --dart-define=API_BASE_URL=http://localhost:4000/api
```

Open:

```text
http://localhost:3000
```

## Demo Credentials

All users use:

```text
password123
```

Roles:

```text
Admin:   admin@school.com
Teacher: teacher@school.com
Parent:  parent@school.com
```

Tap `Send OTP` and use the OTP shown in the app. OTP is valid for about 2 minutes.

## Online Deployment Order

1. Deploy PostgreSQL.
2. Deploy the Node backend from `server/`.
3. Set backend environment variables.
4. Confirm `https://YOUR_BACKEND_DOMAIN/api/health` returns `{"status":"ok"}`.
5. Build Flutter web with the backend URL.
6. Upload `build/web` to a static hosting provider.

## Backend Environment Variables

```text
PORT=4000
DATABASE_URL=postgres://USER:PASSWORD@HOST:PORT/DATABASE
PGSSL=true
JWT_SECRET=change-this-to-a-strong-secret
MESSAGE_ENC_KEY=change-this-to-a-strong-message-key
RAZORPAY_KEY_ID=rzp_test_key
RAZORPAY_KEY_SECRET=rzp_test_secret
```

Use `PGSSL=true` for hosted Postgres providers that require SSL.

## Flutter Web Production Build

After the backend is online:

```bash
flutter build web --dart-define=API_BASE_URL=https://YOUR_BACKEND_DOMAIN/api
```

Deploy this folder:

```text
build/web
```

## Good Hosting Choices

Backend + database:

```text
Railway, Render, Fly.io, or DigitalOcean
```

Frontend:

```text
Netlify, Vercel, Firebase Hosting, or any static web host
```

## Demo Flow

1. Admin logs in and views live operations dashboard.
2. Teacher logs in and marks a student present from `Student QR codes`.
3. Parent logs in and sees the attendance notification.
4. Show secure messaging and Security Center positioning as infrastructure health monitoring.
