/**
 * Creates parent-student relationships linking each parent to corresponding student
 * Run from project root: node server/scripts/seed-parent-student-relationships.js
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

async function createParentStudentRelationships() {
  try {
    console.log('Creating parent-student relationships...');
    
    // Get all parents and students ordered by their insertion order
    const parentsResult = await pool.query('SELECT id, relationship_to_student FROM parents ORDER BY id');
    const studentsResult = await pool.query('SELECT id FROM students ORDER BY id');
    
    const parents = parentsResult.rows;
    const students = studentsResult.rows;
    
    console.log(`Found ${parents.length} parents and ${students.length} students`);
    
    // Create relationships - each parent linked to corresponding student
    for (let i = 0; i < Math.min(parents.length, students.length); i++) {
      const parent = parents[i];
      const student = students[i];
      
      // Normalize relationship type to match database enum
      let relationshipType = parent.relationship_to_student.toLowerCase();
      if (relationshipType === 'father') relationshipType = 'father';
      else if (relationshipType === 'mother') relationshipType = 'mother';
      else relationshipType = 'guardian'; // fallback for any other values
      
      await pool.query(`
        INSERT INTO parent_student_relationships (parent_id, student_id, relationship_type)
        VALUES ($1, $2, $3)
        ON CONFLICT (parent_id, student_id) DO NOTHING
      `, [parent.id, student.id, relationshipType]);
      
      console.log(`Linked ${parent.relationship_to_student} (ID: ${parent.id}) to Student (ID: ${student.id})`);
    }
    
    console.log('Successfully created parent-student relationships!');
    
    // Verify count
    const result = await pool.query('SELECT COUNT(*) FROM parent_student_relationships');
    console.log(`Total parent-student relationships: ${result.rows[0].count}`);
    
  } catch (error) {
    console.error('Error creating relationships:', error);
  } finally {
    await pool.end();
  }
}

createParentStudentRelationships();
