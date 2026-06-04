/**
 * Inserts 50 parents into the database
 * Run from project root: node server/scripts/seed-parents.js
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

const parents = [
  ['Rajesh', 'Sharma', 'rajesh.sharma@example.com', '9876600001', 'Mumbai', 'Businessman', 'Father'],
  ['Sunita', 'Patel', 'sunita.patel@example.com', '9876600002', 'Mumbai', 'Doctor', 'Mother'],
  ['Amit', 'Singh', 'amit.singh@example.com', '9876600003', 'Mumbai', 'Engineer', 'Father'],
  ['Pooja', 'Gupta', 'pooja.gupta@example.com', '9876600004', 'Mumbai', 'Teacher', 'Mother'],
  ['Manoj', 'Mehta', 'manoj.mehta@example.com', '9876600005', 'Mumbai', 'Accountant', 'Father'],
  ['Kavita', 'Rao', 'kavita.rao@example.com', '9876600006', 'Mumbai', 'Lawyer', 'Mother'],
  ['Sanjay', 'Verma', 'sanjay.verma@example.com', '9876600007', 'Mumbai', 'Engineer', 'Father'],
  ['Farah', 'Khan', 'farah.khan@example.com', '9876600008', 'Mumbai', 'Designer', 'Mother'],
  ['Ramesh', 'Reddy', 'ramesh.reddy@example.com', '9876600009', 'Mumbai', 'Contractor', 'Father'],
  ['Lakshmi', 'Nair', 'lakshmi.nair@example.com', '9876600010', 'Mumbai', 'Nurse', 'Mother'],
  ['Deepak', 'Jain', 'deepak.jain@example.com', '9876600011', 'Mumbai', 'Businessman', 'Father'],
  ['Nita', 'Desai', 'nita.desai@example.com', '9876600012', 'Mumbai', 'Teacher', 'Mother'],
  ['Rahul', 'Kapoor', 'rahul.kapoor@example.com', '9876600013', 'Mumbai', 'Actor', 'Father'],
  ['George', 'Thomas', 'george.thomas@example.com', '9876600014', 'Mumbai', 'Manager', 'Father'],
  ['Mary', 'Thomas', 'mary.thomas@example.com', '9876600015', 'Mumbai', 'Homemaker', 'Mother'],
  ['Suresh', 'Das', 'suresh.das@example.com', '9876600016', 'Mumbai', 'Driver', 'Father'],
  ['Neha', 'Singh', 'neha.singh@example.com', '9876600017', 'Mumbai', 'Teacher', 'Mother'],
  ['Arvind', 'Roy', 'arvind.roy@example.com', '9876600018', 'Mumbai', 'Engineer', 'Father'],
  ['Meena', 'Acharya', 'meena.acharya@example.com', '9876600019', 'Mumbai', 'Nurse', 'Mother'],
  ['Rohit', 'Patel', 'rohit.patel@example.com', '9876600020', 'Mumbai', 'Businessman', 'Father'],
  ['Salma', 'Khan', 'salma.khan@example.com', '9876600021', 'Mumbai', 'Homemaker', 'Mother'],
  ['Ravi', 'R', 'ravi.r@example.com', '9876600022', 'Mumbai', 'Mechanic', 'Father'],
  ['Shweta', 'Kapoor', 'shweta.kapoor@example.com', '9876600023', 'Mumbai', 'Designer', 'Mother'],
  ['Mahesh', 'Mehta', 'mahesh.mehta@example.com', '9876600024', 'Mumbai', 'Chartered Accountant', 'Father'],
  ['Kiran', 'Sharma', 'kiran.sharma@example.com', '9876600025', 'Mumbai', 'Teacher', 'Mother'],
  ['Vikas', 'Singh', 'vikas.singh@example.com', '9876600026', 'Mumbai', 'Police Officer', 'Father'],
  ['Harpreet', 'Kaur', 'harpreet.kaur@example.com', '9876600027', 'Mumbai', 'Nurse', 'Mother'],
  ['Ajay', 'Sharma', 'ajay.sharma@example.com', '9876600028', 'Mumbai', 'Engineer', 'Father'],
  ['Leena', 'Nair', 'leena.nair@example.com', '9876600029', 'Mumbai', 'Doctor', 'Mother'],
  ['Prakash', 'Jain', 'prakash.jain@example.com', '9876600030', 'Mumbai', 'Businessman', 'Father'],
  ['Rohit', 'Verma', 'rohit.verma@example.com', '9876600031', 'Mumbai', 'IT Professional', 'Father'],
  ['Anita', 'Das', 'anita.das@example.com', '9876600032', 'Mumbai', 'Teacher', 'Mother'],
  ['Imran', 'Ali', 'imran.ali@example.com', '9876600033', 'Mumbai', 'Shop Owner', 'Father'],
  ['Soma', 'Sen', 'soma.sen@example.com', '9876600034', 'Mumbai', 'Professor', 'Mother'],
  ['Vijay', 'Bhatt', 'vijay.bhatt@example.com', '9876600035', 'Mumbai', 'Engineer', 'Father'],
  ['Anil', 'Gupta', 'anil.gupta@example.com', '9876600036', 'Mumbai', 'Businessman', 'Father'],
  ['Padma', 'Reddy', 'padma.reddy@example.com', '9876600037', 'Mumbai', 'Teacher', 'Mother'],
  ['Subhash', 'Roy', 'subhash.roy@example.com', '9876600038', 'Mumbai', 'Manager', 'Father'],
  ['Sunita', 'Das', 'sunita.das@example.com', '9876600039', 'Mumbai', 'Homemaker', 'Mother'],
  ['Krishna', 'Nair', 'krishna.nair@example.com', '9876600040', 'Mumbai', 'Driver', 'Father'],
  ['Aslam', 'Khan', 'aslam.khan@example.com', '9876600041', 'Mumbai', 'Shop Owner', 'Father'],
  ['Rekha', 'Singh', 'rekha.singh@example.com', '9876600042', 'Mumbai', 'Teacher', 'Mother'],
  ['Manish', 'Patel', 'manish.patel@example.com', '9876600043', 'Mumbai', 'Engineer', 'Father'],
  ['Sanjay', 'Joshi', 'sanjay.joshi@example.com', '9876600044', 'Mumbai', 'Lawyer', 'Father'],
  ['Ritu', 'Gupta', 'ritu.gupta@example.com', '9876600045', 'Mumbai', 'Doctor', 'Mother'],
  ['Rajiv', 'Das', 'rajiv.das@example.com', '9876600046', 'Mumbai', 'Businessman', 'Father'],
  ['Mehul', 'Shah', 'mehul.shah@example.com', '9876600047', 'Mumbai', 'Chartered Accountant', 'Father'],
  ['Ashok', 'Jain', 'ashok.jain@example.com', '9876600048', 'Mumbai', 'Trader', 'Father'],
  ['Rakesh', 'Goyal', 'rakesh.goyal@example.com', '9876600049', 'Mumbai', 'Businessman', 'Father'],
  ['Sridhar', 'Iyer', 'sridhar.iyer@example.com', '9876600050', 'Mumbai', 'Engineer', 'Father']
];

async function insertParents() {
  try {
    console.log('Inserting 50 parents...');
    
    for (const parent of parents) {
      const [first_name, last_name, email, phone, address, occupation, relationship_to_student] = parent;
      
      await pool.query(`
        INSERT INTO parents (first_name, last_name, email, phone, address, occupation, relationship_to_student)
        VALUES ($1, $2, $3, $4, $5, $6, $7)
        ON CONFLICT (email) DO NOTHING
      `, [first_name, last_name, email, phone, address, occupation, relationship_to_student]);
    }
    
    console.log('Successfully inserted 50 parents!');
    
    // Verify count
    const result = await pool.query('SELECT COUNT(*) FROM parents');
    console.log(`Total parents in database: ${result.rows[0].count}`);
    
  } catch (error) {
    console.error('Error inserting parents:', error);
  } finally {
    await pool.end();
  }
}

insertParents();
