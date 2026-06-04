import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import rateLimit from 'express-rate-limit';
import dotenv from 'dotenv';

import { authRouter } from './routes/auth.js';
import { attendanceRouter } from './routes/attendance.js';
import { homeworkRouter } from './routes/homework.js';
import { feesRouter } from './routes/fees.js';
import { gradesRouter } from './routes/grades.js';
import { chatRouter } from './routes/chat.js';
import { securityRouter } from './routes/security.js';
import { dashboardRouter } from './routes/dashboard.js';
import { ensureDatabaseReady } from './initDb.js';

dotenv.config();

const app = express();

app.use(helmet());
app.use(cors());
app.use(express.json());

const limiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 100,
});
app.use(limiter);

app.get('/api/health', (req, res) => {
  res.json({ status: 'ok' });
});

app.use('/api/auth', authRouter);
app.use('/api/attendance', attendanceRouter);
app.use('/api/homework', homeworkRouter);
app.use('/api/fees', feesRouter);
app.use('/api/grades', gradesRouter);
app.use('/api/chat', chatRouter);
app.use('/api/security', securityRouter);
app.use('/api/dashboard', dashboardRouter);

const port = process.env.PORT || 4000;

ensureDatabaseReady()
  .then(() => {
    app.listen(port, () => {
      // eslint-disable-next-line no-console
      console.log(`SecureSchoolHub server listening on port ${port}`);
    });
  })
  .catch((error) => {
    // eslint-disable-next-line no-console
    console.error('Database initialization failed:', error);
    process.exit(1);
  });
