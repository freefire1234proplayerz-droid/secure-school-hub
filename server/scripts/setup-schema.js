/**
 * Creates database schema for students, parents, and teachers
 * Run from project root: node server/scripts/setup-schema.js
 */
import pg from 'pg';
import dotenv from 'dotenv';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
dotenv.config({ path: path.join(__dirname, '../.env') });

const pool = new pg.Pool({
  host: 'localhost',
  port: 5432,
  database: 'secure_school_hub',
  user: 'secure_school_hub',
  password: 'secure_school_hub',
});

async function setupSchema() {
  try {
    // Create parents table first (no dependencies)
    await pool.query(`
      CREATE TABLE IF NOT EXISTS parents (
        id SERIAL PRIMARY KEY,
        first_name TEXT NOT NULL,
        last_name TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL,
        phone TEXT NOT NULL,
        address TEXT,
        occupation TEXT,
        relationship_to_student TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `);

    // Create teachers table (no dependencies)
    await pool.query(`
      CREATE TABLE IF NOT EXISTS teachers (
        id SERIAL PRIMARY KEY,
        first_name TEXT NOT NULL,
        last_name TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL,
        phone TEXT,
        subject TEXT,
        grade INTEGER,
        section TEXT,
        employee_id TEXT UNIQUE,
        address TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `);

    // Create students table (references parents)
    await pool.query(`
      CREATE TABLE IF NOT EXISTS students (
        id SERIAL PRIMARY KEY,
        first_name TEXT NOT NULL,
        last_name TEXT NOT NULL,
        email TEXT UNIQUE,
        phone TEXT,
        date_of_birth DATE,
        grade INTEGER,
        section TEXT,
        roll_number TEXT UNIQUE,
        address TEXT,
        parent_id INTEGER REFERENCES parents(id),
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `);

    // Create parent-student relationships table
    await pool.query(`
      CREATE TABLE IF NOT EXISTS parent_student_relationships (
        id SERIAL PRIMARY KEY,
        parent_id INTEGER REFERENCES parents(id) ON DELETE CASCADE,
        student_id INTEGER REFERENCES students(id) ON DELETE CASCADE,
        relationship_type TEXT NOT NULL CHECK (relationship_type IN ('father', 'mother', 'guardian')),
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        UNIQUE(parent_id, student_id)
      );
    `);

    console.log('Database schema created successfully!');
    console.log('Tables created: parents, teachers, students, parent_student_relationships');
    
  } catch (error) {
    console.error('Error creating schema:', error);
  } finally {
    await pool.end();
  }
}

setupSchema();
