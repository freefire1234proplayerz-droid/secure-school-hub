# Secure School Hub User Management

## Scope

The administration module lets admins create and manage students, teachers,
parents, and admins from the existing Admin AppShell. It adds secure password
handling, admission records, account status controls, search filters, audit
logs, database dashboard metrics, and CSV export for Excel.

## Database Schema

### users

Core login table used by JWT authentication.

| Column | Purpose |
| --- | --- |
| `id` | Primary key |
| `email` | Unique login email |
| `password_hash` | bcrypt hash, never the raw password |
| `role` | `student`, `teacher`, `parent`, or `admin` |
| `totp_secret` | OTP secret for the current login flow |
| `first_name`, `last_name`, `phone` | Directory profile fields |
| `status` | `active` or `disabled` |
| `disabled_at` | Timestamp when access was disabled |
| `created_at`, `updated_at` | Lifecycle timestamps |

### students

Admission table linked to student users by email and to parents by
`parent_user_id`.

| Column | Purpose |
| --- | --- |
| `id` | Primary key |
| `admission_no` | Auto-generated student ID such as `SSH-00001` |
| `first_name`, `last_name`, `name` | Student name fields |
| `grade`, `section`, `class_name` | Class/division assignment |
| `roll_number`, `roll_no` | Roll number compatibility fields |
| `email`, `phone`, `address` | Student contact details |
| `parent_user_id` | Assigned parent account |
| `qr_code` | Attendance QR identity |
| `status` | Student record status |

### audit_logs

Append-only activity log for administrative and security events.

| Column | Purpose |
| --- | --- |
| `actor_user_id` | User who performed the action |
| `target_user_id` | User affected by the action |
| `target_student_id` | Student affected by the action |
| `action` | Event key such as `user_created` |
| `category` | `login`, `attendance_actions`, `user_creation`, `password_changes` |
| `detail` | Human-readable event summary |
| `metadata` | JSONB event context |
| `ip_address`, `user_agent` | Request source metadata |
| `created_at` | Event timestamp |

## APIs

All `/api/admin/*` endpoints require a valid admin JWT.

| Method | Endpoint | Purpose |
| --- | --- | --- |
| `GET` | `/api/admin/users` | List users with `role`, `status`, `class`, and `search` filters |
| `GET` | `/api/admin/parents` | Parent picker for admission assignment |
| `POST` | `/api/admin/users` | Create student, teacher, parent, or admin |
| `PATCH` | `/api/admin/users/:id/status` | Enable or disable an account |
| `POST` | `/api/admin/users/:id/reset-password` | bcrypt-hash and replace a password |
| `GET` | `/api/admin/audit-logs` | Recent audit events |
| `GET` | `/api/admin/dashboard` | Counts, class totals, audit totals, and database size |
| `GET` | `/api/admin/export/users.csv` | Excel-compatible CSV export |

Authentication APIs also write audit records for successful OTP login and
blocked disabled-account login attempts. Attendance marking writes
`attendance_actions` audit records.

## Workflows

### Admit Student

1. Admin opens Admin Operations > Users.
2. Selects `Student`, enters login/profile details, class, division, roll
   number, and parent.
3. Backend creates a bcrypt-hashed user account.
4. Backend auto-generates `admission_no` and a QR code identity.
5. Audit log records `student_admitted`.

### Create Staff, Parent, Or Admin

1. Admin selects the target role.
2. Backend validates email uniqueness and minimum password length.
3. Password is hashed with bcrypt before storage.
4. Audit log records `user_created`.

### Disable Or Enable Account

1. Admin clicks the status action in the directory.
2. Backend sets `users.status` to `disabled` or `active`.
3. Disabled users cannot complete login or OTP verification.
4. Audit log records `account_disabled` or `account_enabled`.

### Reset Password

1. Admin selects a user and enters a replacement password.
2. Backend hashes the new password using bcrypt.
3. Audit log records `password_reset`.

### Search, Filter, And Export

Admins can filter the directory by role, class, and status, plus text search
across email, names, and admission numbers. Export returns CSV that can be
opened in Excel or pasted from the app clipboard.
