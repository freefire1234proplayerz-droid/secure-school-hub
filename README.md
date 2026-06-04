## SecureSchoolHub

SecureSchoolHub is a full-stack Flutter + Node.js solution for Indian tier1/tier2 schools.  
It provides secure teacher and parent dashboards with QR attendance, homework, fee reminders (Razorpay), real-time notifications (via FCM), grades, chat with E2E-style encryption, and a basic Nmap-based network scan tool.

### Stack

- **Mobile app**: Flutter (Android/iOS), Material 3 UI, Hindi/English toggle, offline-capable via Hive local DB sync.
- **Backend**: Node.js/Express, PostgreSQL (Dockerized), JWT auth, TOTP-based 2FA, encrypted chat messages, Nmap wrapper for basic vulnerability scanning.
- **Deployment**: Docker Compose on Ubuntu Server with UFW firewall, Nginx + Certbot (Let's Encrypt SSL), WireGuard VPN bootstrap script.

### Project structure

- `pubspec.yaml` – Flutter dependencies.
- `lib/` – Flutter app:
  - `main.dart` – app entrypoint, localization, theme, providers.
  - `l10n/app_localizations.dart` – simple Hindi/English strings.
  - `providers/locale_provider.dart` – language toggle.
  - `screens/login_screen.dart` – JWT + 2FA login flow.
  - `screens/teacher_dashboard.dart` – QR attendance, homework, fees, security scan.
  - `screens/parent_dashboard.dart` – grades view stub, secure chat UI.
  - `services/local_db.dart` – Hive boxes for auth + offline cache.
  - `services/api_service.dart` – Dio API client with offline pending-actions pattern.
  - `services/auth_service.dart` – login + OTP verification + session handling.
  - `widgets/language_toggle.dart` – Hindi/English segmented control.
- `server/` – Node backend:
  - `package.json`, `Dockerfile`, `.env.example`.
  - `src/index.js` – Express app + route wiring.
  - `src/db.js` – PostgreSQL pool helper.
  - `src/middleware/auth.js` – JWT auth middleware.
  - `src/utils/crypto.js` – AES encryption helpers for chat messages.
  - `src/routes/*.js` – modular routes for auth, attendance, homework, fees, grades, chat, security.
- `docker-compose.yml` – services for `db` (Postgres) and `server`.
- `scripts/setup_ubuntu_secure_school_hub.sh` – Ubuntu setup helper (UFW, Docker, Nginx, Certbot, WireGuard).

### Database schema (baseline)

Run this SQL against the Postgres instance (e.g. via `psql` in the `db` container):

```sql
CREATE TABLE IF NOT EXISTS users (
  id SERIAL PRIMARY KEY,
  email TEXT UNIQUE NOT NULL,
  password_hash TEXT NOT NULL,
  role TEXT NOT NULL CHECK (role IN ('teacher', 'parent')),
  totp_secret TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS attendance (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL REFERENCES users(id),
  qr_data TEXT NOT NULL,
  marked_at TIMESTAMP WITH TIME ZONE NOT NULL
);

CREATE TABLE IF NOT EXISTS homework (
  id SERIAL PRIMARY KEY,
  teacher_id INTEGER NOT NULL REFERENCES users(id),
  title TEXT NOT NULL,
  description TEXT,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL
);

CREATE TABLE IF NOT EXISTS grades (
  id SERIAL PRIMARY KEY,
  student_id INTEGER NOT NULL REFERENCES users(id),
  subject TEXT NOT NULL,
  score NUMERIC NOT NULL,
  max_score NUMERIC NOT NULL,
  term TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS messages (
  id SERIAL PRIMARY KEY,
  sender_id INTEGER NOT NULL REFERENCES users(id),
  body_enc TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL
);
```

> **Note**: Chat messages are stored AES-encrypted via `MESSAGE_ENC_KEY`. For true E2E you would manage per-device keys and avoid server-side decryption; this repo uses server-side encryption for simplicity.

### How to log in (local)

1. **Start backend**: `docker compose up -d --build`
2. **Install server deps and create tables + seed users** (from project root):

```bash
cd server
npm install
DATABASE_URL="postgres://secure_school_hub:secure_school_hub@localhost:5432/secure_school_hub" node scripts/seed-user.js
```

3. **Open the app** and use:
   - **Teacher**: email `teacher@school.com`, password `password123`, choose **Teacher**, tap **Send OTP**. Enter the 6-digit OTP shown on the screen (demo) and tap **Verify OTP**.
   - **Parent**: email `parent@school.com`, password `password123`, choose **Parent**, then same OTP step.

The app shows the current demo OTP after you tap Send OTP so you can log in without a TOTP app.

### Backend configuration

Copy `.env.example` to `.env` inside `server/` and adjust values:

```bash
cd server
cp .env.example .env
```

Key variables:

- `DATABASE_URL` – e.g. `postgres://secure_school_hub:secure_school_hub@db:5432/secure_school_hub` for Docker.
- `JWT_SECRET` – strong random secret.
- `MESSAGE_ENC_KEY` – strong random key for message encryption.
- `RAZORPAY_KEY_ID` / `RAZORPAY_KEY_SECRET` – Razorpay credentials.

### Local backend (Docker) on Linux

```bash
docker compose up -d --build
```

This starts:

- `db` – Postgres on internal Docker network.
- `server` – Express API on port `4000`.

Health check:

```bash
curl http://localhost:4000/api/health
```

### Flutter app (Android/iOS)

1. Install Flutter SDK and Android/iOS tooling.
2. Configure Firebase for FCM (create a Firebase project, add Android/iOS apps, download `google-services.json` / `GoogleService-Info.plist` and integrate as usual).
3. In the Flutter app, set the API base URL using a compile-time define (or update `ApiService` default):

```bash
flutter run --dart-define=API_BASE_URL=https://your-domain.com/api
```

Offline capabilities:

- All auth tokens and generic cached data use Hive (`LocalDb`).
- `ApiService.syncPendingActions()` shows how to queue API requests locally when offline and replay them later.

### Ubuntu Server deployment steps

1. **Provision server**
   - Ubuntu 22.04 LTS, at least 2 vCPU, 4 GB RAM recommended.
   - Point your domain’s DNS A-record to the server IP.

2. **Copy project**

```bash
ssh ubuntu@your-server
sudo mkdir -p /opt/secure-school-hub
sudo chown "$USER":"$USER" /opt/secure-school-hub

# On your local machine:
rsync -av . ubuntu@your-server:/opt/secure-school-hub/
```

3. **Run setup script**

```bash
ssh ubuntu@your-server
cd /opt/secure-school-hub
chmod +x scripts/setup_ubuntu_secure_school_hub.sh
./scripts/setup_ubuntu_secure_school_hub.sh your-domain.com admin@your-domain.com
```

The script:

- Installs Docker, UFW, Certbot, WireGuard.
- Enables UFW for SSH/HTTP/HTTPS and WireGuard UDP port.
- Brings up `docker-compose.yml` (Postgres + Node server).
- Sets up Nginx reverse proxy on port 80 -> 4000.
- Requests Let’s Encrypt certificate via Certbot (HTTPS).

4. **WireGuard VPN**

- Script creates a base `/etc/wireguard/wg0.conf`.  
- Add peers manually for admin devices, e.g.:

```ini
[Peer]
PublicKey = <client-public-key>
AllowedIPs = 10.8.0.2/32
```

Restart WireGuard: `sudo systemctl restart wg-quick@wg0`.

### Security notes

- Change all default secrets in `.env`.
- Restrict Nmap `target` values to internal IPs only (already enforced in route).
- Consider using Postgres `pgcrypto` for column-level encryption in production.
- For real E2E chat, migrate to per-device keypairs and avoid server-side decryption.

