/**
 * Inserts 5 teachers into the database
 * Run from project root: node server/scripts/seed-teachers.js
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

const teachers = [
  ['Rajesh', 'Kumar', 'rajesh.kumar@school.com', '9876700001', 'Mathematics', 10, 'A', 'T001', 'Mumbai'],
  ['Anjali', 'Rao', 'anjali.rao@school.com', '9876700002', 'Science', 9, 'A', 'T002', 'Mumbai'],
  ['Priya', 'Singh', 'priya.singh@school.com', '9876700003', 'English', 8, 'A', 'T003', 'Mumbai'],
  ['Vikram', 'Patel', 'vikram.patel@school.com', '9876700004', 'Social Studies', 7, 'A', 'T004', 'Mumbai'],
  ['Neha', 'Mehta', 'neha.mehta@school.com', '9876700005', 'Computer Science', 6, 'A', 'T005', 'Mumbai']
];

async function insertTeachers() {
  try {
    console.log('Inserting 5 teachers...');
    
    for (const teacher of teachers) {
      const [first_name, last_name, email, phone, subject, grade, section, employee_id, address] = teacher;
      
      await pool.query(`
        INSERT INTO teachers (first_name, last_name, email, phone, subject, grade, section, employee_id, address)
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
        ON CONFLICT (email) DO NOTHING
      `, [first_name, last_name, email, phone, subject, grade, section, employee_id, address]);
    }
    
    console.log('Successfully inserted 5 teachers!');
    
    // Verify count
    const result = await pool.query('SELECT COUNT(*) FROM teachers');
    console.log(`Total teachers in database: ${result.rows[0].count}`);
    
  } catch (error) {
    console.error('Error inserting teachers:', error);
  } finally {
    await pool.end();
  }
}

insertTeachers();
