/**
 * Inserts 50 students into the database
 * Run from project root: node server/scripts/seed-students.js
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

const students = [
  ['Aarav', 'Sharma', 'aarav.sharma@example.com', '9876500001', '2010-01-12', 10, 'A', '10A01', 'Mumbai'],
  ['Diya', 'Patel', 'diya.patel@example.com', '9876500002', '2010-03-22', 10, 'A', '10A02', 'Mumbai'],
  ['Rohan', 'Singh', 'rohan.singh@example.com', '9876500003', '2010-07-15', 10, 'A', '10A03', 'Mumbai'],
  ['Isha', 'Gupta', 'isha.gupta@example.com', '9876500004', '2010-04-18', 10, 'A', '10A04', 'Mumbai'],
  ['Kabir', 'Mehta', 'kabir.mehta@example.com', '9876500005', '2010-06-09', 10, 'A', '10A05', 'Mumbai'],
  ['Ananya', 'Rao', 'ananya.rao@example.com', '9876500006', '2011-01-25', 9, 'A', '09A01', 'Mumbai'],
  ['Yash', 'Verma', 'yash.verma@example.com', '9876500007', '2011-02-19', 9, 'A', '09A02', 'Mumbai'],
  ['Sana', 'Khan', 'sana.khan@example.com', '9876500008', '2011-09-10', 9, 'A', '09A03', 'Mumbai'],
  ['Arjun', 'Reddy', 'arjun.reddy@example.com', '9876500009', '2011-12-02', 9, 'A', '09A04', 'Mumbai'],
  ['Meera', 'Nair', 'meera.nair@example.com', '9876500010', '2011-03-15', 9, 'A', '09A05', 'Mumbai'],
  ['Devansh', 'Jain', 'devansh.jain@example.com', '9876500011', '2012-04-10', 8, 'A', '08A01', 'Mumbai'],
  ['Pooja', 'Desai', 'pooja.desai@example.com', '9876500012', '2012-05-23', 8, 'A', '08A02', 'Mumbai'],
  ['Aria', 'Kapoor', 'aria.kapoor@example.com', '9876500013', '2012-07-08', 8, 'A', '08A03', 'Mumbai'],
  ['Neil', 'George', 'neil.george@example.com', '9876500014', '2012-11-19', 8, 'A', '08A04', 'Mumbai'],
  ['Riya', 'Thomas', 'riya.thomas@example.com', '9876500015', '2012-10-30', 8, 'A', '08A05', 'Mumbai'],
  ['Vivaan', 'Das', 'vivaan.das@example.com', '9876500016', '2013-02-12', 7, 'A', '07A01', 'Mumbai'],
  ['Khushi', 'Singh', 'khushi.singh@example.com', '9876500017', '2013-06-22', 7, 'A', '07A02', 'Mumbai'],
  ['Shaurya', 'Roy', 'shaurya.roy@example.com', '9876500018', '2013-08-17', 7, 'A', '07A03', 'Mumbai'],
  ['Tara', 'Acharya', 'tara.acharya@example.com', '9876500019', '2013-03-04', 7, 'A', '07A04', 'Mumbai'],
  ['Kabir', 'Patel', 'kabir.patel@example.com', '9876500020', '2013-12-11', 7, 'A', '07A05', 'Mumbai'],
  ['Sara', 'Khan', 'sara.khan@example.com', '9876500021', '2014-01-14', 6, 'A', '06A01', 'Mumbai'],
  ['Rohan', 'R', 'rohan.r@example.com', '9876500022', '2014-05-20', 6, 'A', '06A02', 'Mumbai'],
  ['Mia', 'Kapoor', 'mia.kapoor@example.com', '9876500023', '2014-07-19', 6, 'A', '06A03', 'Mumbai'],
  ['Aryan', 'Mehta', 'aryan.mehta@example.com', '9876500024', '2014-09-02', 6, 'A', '06A04', 'Mumbai'],
  ['Naina', 'Sharma', 'naina.sharma@example.com', '9876500025', '2014-12-10', 6, 'A', '06A05', 'Mumbai'],
  ['Karan', 'Singh', 'karan.singh@example.com', '9876500026', '2015-02-13', 5, 'A', '05A01', 'Mumbai'],
  ['Simran', 'Kaur', 'simran.kaur@example.com', '9876500027', '2015-03-21', 5, 'A', '05A02', 'Mumbai'],
  ['Aditya', 'Sharma', 'aditya.sharma@example.com', '9876500028', '2015-04-17', 5, 'A', '05A03', 'Mumbai'],
  ['Zara', 'Nair', 'zara.nair@example.com', '9876500029', '2015-07-05', 5, 'A', '05A04', 'Mumbai'],
  ['Reyansh', 'Jain', 'reyansh.jain@example.com', '9876500030', '2015-09-11', 5, 'A', '05A05', 'Mumbai'],
  ['Ishaan', 'Verma', 'ishaan.verma@example.com', '9876500031', '2016-01-22', 4, 'A', '04A01', 'Mumbai'],
  ['Anika', 'Das', 'anika.das@example.com', '9876500032', '2016-02-18', 4, 'A', '04A02', 'Mumbai'],
  ['Kabir', 'Ali', 'kabir.ali@example.com', '9876500033', '2016-03-26', 4, 'A', '04A03', 'Mumbai'],
  ['Riya', 'Sen', 'riya.sen@example.com', '9876500034', '2016-04-14', 4, 'A', '04A04', 'Mumbai'],
  ['Arya', 'Bhatt', 'arya.bhatt@example.com', '9876500035', '2016-06-30', 4, 'A', '04A05', 'Mumbai'],
  ['Rudra', 'Gupta', 'rudra.gupta@example.com', '9876500036', '2017-01-11', 3, 'A', '03A01', 'Mumbai'],
  ['Anushka', 'Reddy', 'anushka.reddy@example.com', '9876500037', '2017-02-23', 3, 'A', '03A02', 'Mumbai'],
  ['Kabir', 'Roy', 'kabir.roy@example.com', '9876500038', '2017-04-10', 3, 'A', '03A03', 'Mumbai'],
  ['Sara', 'Das', 'sara.das@example.com', '9876500039', '2017-05-12', 3, 'A', '03A04', 'Mumbai'],
  ['Vihaan', 'Nair', 'vihaan.nair@example.com', '9876500040', '2017-06-18', 3, 'A', '03A05', 'Mumbai'],
  ['Ayaan', 'Khan', 'ayaan.khan@example.com', '9876500041', '2018-01-02', 2, 'A', '02A01', 'Mumbai'],
  ['Anaya', 'Singh', 'anaya.singh@example.com', '9876500042', '2018-02-14', 2, 'A', '02A02', 'Mumbai'],
  ['Reyanshi', 'Patel', 'reyanshi.patel@example.com', '9876500043', '2018-03-20', 2, 'A', '02A03', 'Mumbai'],
  ['Arnav', 'Joshi', 'arnav.joshi@example.com', '9876500044', '2018-04-25', 2, 'A', '02A04', 'Mumbai'],
  ['Kiara', 'R', 'kiara.r@example.com', '9876500045', '2018-05-16', 2, 'A', '02A05', 'Mumbai'],
  ['Tanishq', 'Das', 'tanishq.das@example.com', '9876500046', '2019-01-07', 1, 'A', '01A01', 'Mumbai'],
  ['Myra', 'Shah', 'myra.shah@example.com', '9876500047', '2019-02-18', 1, 'A', '01A02', 'Mumbai'],
  ['Prisha', 'Jain', 'prisha.jain@example.com', '9876500048', '2019-03-10', 1, 'A', '01A03', 'Mumbai'],
  ['Aryan', 'G', 'aryan.g@example.com', '9876500049', '2019-04-14', 1, 'A', '01A04', 'Mumbai'],
  ['Zoya', 'Iyer', 'zoya.iyer@example.com', '9876500050', '2019-05-22', 1, 'A', '01A05', 'Mumbai']
];

async function insertStudents() {
  try {
    console.log('Inserting 50 students...');
    
    for (const student of students) {
      const [first_name, last_name, email, phone, date_of_birth, grade, section, roll_number, address] = student;
      
      await pool.query(`
        INSERT INTO students (first_name, last_name, email, phone, date_of_birth, grade, section, roll_number, address)
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
        ON CONFLICT (email) DO NOTHING
      `, [first_name, last_name, email, phone, date_of_birth, grade, section, roll_number, address]);
    }
    
    console.log('Successfully inserted 50 students!');
    
    // Verify count
    const result = await pool.query('SELECT COUNT(*) FROM students');
    console.log(`Total students in database: ${result.rows[0].count}`);
    
  } catch (error) {
    console.error('Error inserting students:', error);
  } finally {
    await pool.end();
  }
}

insertStudents();
