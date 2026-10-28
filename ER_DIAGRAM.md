# Entity-Relationship Diagram

## ER Diagram (Mermaid)

```mermaid
erDiagram
    USERS ||--o{ ATTENDANCE : "marks (teacher)"
    USERS ||--o{ HOMEWORK : "creates (teacher)"
    USERS ||--o{ HOMEWORK_FILES : "uploads (teacher)"
    USERS ||--o{ MESSAGES : "sends"
    USERS ||--o{ NOTIFICATIONS : "receives"
    USERS ||--o{ AUDIT_LOGS : "acts as actor"
    USERS ||--o{ AUDIT_LOGS : "target user"
    USERS ||--o{ STUDENTS : "parent of"
    USERS ||--o{ FEE_FILES : "uploads"
    USERS ||--o{ AUDIT_LOGS : "target student (admin)"

    STUDENTS ||--o{ ATTENDANCE : "marked for"
    STUDENTS ||--o{ GRADES : "has"
    STUDENTS ||--o{ FEE_RECORDS : "owes"
    STUDENTS ||--o{ NOTIFICATIONS : "triggers (via parent)"

    HOMEWORK ||--o{ HOMEWORK_FILES : "has attachments"

    USERS {
        int id PK
        string email UK
        string password_hash
        enum role "student|teacher|parent|admin"
        string totp_secret
        string first_name
        string last_name
        string phone
        enum status "active|disabled"
        timestamp disabled_at
        timestamp created_at
        timestamp updated_at
    }

    STUDENTS {
        int id PK
        string first_name
        string last_name
        int grade
        string section
        string roll_number UK
        string email UK
        string phone
        string address
        string name
        string class_name
        string roll_no
        int parent_user_id FK
        string qr_code UK
        string admission_no UK
        enum status "active|inactive"
        timestamp created_at
        timestamp updated_at
    }

    ATTENDANCE {
        int id PK
        int user_id FK "teacher who marked"
        int student_id FK
        string qr_data
        timestamp marked_at
    }

    AUDIT_LOGS {
        int id PK
        int actor_user_id FK
        int target_user_id FK
        int target_student_id FK
        string action
        string category
        string detail
        jsonb metadata
        string ip_address
        string user_agent
        timestamp created_at
    }

    HOMEWORK {
        int id PK
        int teacher_id FK
        string title
        string description
        timestamp created_at
    }

    HOMEWORK_FILES {
        int id PK
        int homework_id FK
        int teacher_id FK
        string file_name
        bigint file_size
        timestamp created_at
    }

    GRADES {
        int id PK
        int student_id FK
        string subject
        numeric score
        numeric max_score
        string term
    }

    FEE_RECORDS {
        int id PK
        int student_id FK
        numeric amount
        string currency "INR"
        enum status "pending|paid|overdue"
        string razorpay_order_id
        string razorpay_payment_id
        date due_date
        timestamp created_at
        timestamp updated_at
    }

    FEE_FILES {
        int id PK
        int user_id FK
        enum role "teacher|parent|admin"
        string file_name
        bigint file_size
        timestamp created_at
    }

    MESSAGES {
        int id PK
        int sender_id FK
        string body_enc "AES encrypted"
        timestamp created_at
    }

    NOTIFICATIONS {
        int id PK
        int user_id FK
        string title
        string body
        string type "attendance|homework|fee|chat|system"
        timestamp created_at
        timestamp read_at
    }
```

## Relationship Summary

| Parent Entity | Child Entity | Relationship | Cardinality | Notes |
|--------------|--------------|--------------|-------------|-------|
| USERS | ATTENDANCE | marks | 1:N | Teacher marks attendance |
| USERS | HOMEWORK | creates | 1:N | Teacher creates homework |
| USERS | HOMEWORK_FILES | uploads | 1:N | Teacher attaches files |
| USERS | MESSAGES | sends | 1:N | Chat messages |
| USERS | NOTIFICATIONS | receives | 1:N | All notifications |
| USERS | AUDIT_LOGS | acts | 1:N | Actor in audit |
| USERS | AUDIT_LOGS | targeted | 1:N | Target user |
| USERS | STUDENTS | parent of | 1:N | Parent->child link |
| USERS | FEE_FILES | uploads | 1:N | Fee proof uploads |
| STUDENTS | ATTENDANCE | marked for | 1:N | Student attendance |
| STUDENTS | GRADES | has | 1:N | Academic grades |
| STUDENTS | FEE_RECORDS | owes | 1:N | Fee obligations |
| HOMEWORK | HOMEWORK_FILES | has | 1:N | Attachments |

## Key Constraints & Indexes

```sql
-- Users
CREATE UNIQUE INDEX users_email_unique ON users(email);
CREATE INDEX users_role_idx ON users(role);
CREATE INDEX users_status_idx ON users(status);

-- Students
CREATE UNIQUE INDEX students_qr_code_unique ON students(qr_code);
CREATE UNIQUE INDEX students_admission_no_unique ON students(admission_no);
CREATE INDEX students_parent_user_id_idx ON students(parent_user_id);
CREATE INDEX students_class_name_idx ON students(class_name);

-- Attendance
CREATE INDEX attendance_student_id_idx ON attendance(student_id);
CREATE INDEX attendance_marked_at_idx ON attendance(marked_at);
CREATE INDEX attendance_user_id_idx ON attendance(user_id);

-- Homework
CREATE INDEX homework_teacher_id_idx ON homework(teacher_id);
CREATE INDEX homework_created_at_idx ON homework(created_at DESC);

-- Grades
CREATE INDEX grades_student_id_idx ON grades(student_id);
CREATE UNIQUE INDEX grades_student_subject_term_unique
  ON grades(student_id, subject, term);

-- Fee Records
CREATE INDEX fee_records_student_id_idx ON fee_records(student_id);
CREATE INDEX fee_records_status_idx ON fee_records(status);

-- Messages
CREATE INDEX messages_sender_id_idx ON messages(sender_id);
CREATE INDEX messages_created_at_idx ON messages(created_at DESC);

-- Notifications
CREATE INDEX notifications_user_id_idx ON notifications(user_id);
CREATE INDEX notifications_read_at_idx ON notifications(read_at);
CREATE INDEX notifications_type_idx ON notifications(type);

-- Audit Logs
CREATE INDEX audit_logs_actor_user_id_idx ON audit_logs(actor_user_id);
CREATE INDEX audit_logs_target_user_id_idx ON audit_logs(target_user_id);
CREATE INDEX audit_logs_created_at_idx ON audit_logs(created_at DESC);
CREATE INDEX audit_logs_category_idx ON audit_logs(category);
```

## Data Flow Notes

1. **Attendance**: Teacher scans QR → creates Attendance record → creates parent Notification → FCM push to parent
2. **Homework**: Teacher creates → Homework record → optional Homework_files → notifyAllParents() → Notification to all parents
3. **Grades**: Admin/teacher inserts → linked to Student (not User) → Parent dashboard queries via student_id
4. **Chat**: Sender encrypts with MESSAGE_ENC_KEY → stored as body_enc → decrypt on read → notify opposite role
5. **Fees**: Teacher creates fee_remind → Razorpay order → notifyAllParents() → Parent uploads proof → fee_files → notifyAllTeachers()
6. **Audit**: All security actions (login, user CRUD, password reset, attendance) → audit_logs with actor, target, metadata
7. **AI Tutor**: User asks → JWT verified → Gemini API with retry/fallback → response returned

## Soft Deletes & Status Fields

- `users.status`: 'active' | 'disabled' (soft delete via disabled_at)
- `students.status`: 'active' | 'inactive'
- `fee_records.status`: 'pending' | 'paid' | 'overdue'
- `notifications.read_at`: NULL = unread, timestamp = read

No hard deletes on core entities; use status fields for lifecycle management.