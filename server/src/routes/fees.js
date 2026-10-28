import express from 'express';
import Razorpay from 'razorpay';
import dotenv from 'dotenv';

import { authRequired } from '../middleware/auth.js';
import { query } from '../db.js';
import { notifyAllParents, notifyAllTeachers } from '../utils/notify.js';
import { feesRemindValidation, feesAttachValidation } from '../middleware/validate.js';

dotenv.config();

export const feesRouter = express.Router();

const razorpay = new Razorpay({
  key_id: process.env.RAZORPAY_KEY_ID || 'rzp_test_key',
  key_secret: process.env.RAZORPAY_KEY_SECRET || 'rzp_test_secret',
});

async function ensureFeeFilesTable() {
  await query(`
    CREATE TABLE IF NOT EXISTS fee_files (
      id SERIAL PRIMARY KEY,
      user_id INTEGER REFERENCES users(id),
      role TEXT NOT NULL,
      file_name TEXT NOT NULL,
      file_size BIGINT,
      created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
    );
  `);
}

feesRouter.post('/remind', authRequired, feesRemindValidation, async (req, res) => {
  const { amount, currency } = req.body;
  const amountInr = amount || 5000;
  let order = null;

  try {
    order = await razorpay.orders.create({
      amount: amountInr * 100,
      currency: currency || 'INR',
      receipt: `fee_${Date.now()}`,
    });
  } catch (e) {
    order = {
      id: `demo_order_${Date.now()}`,
      amount: amountInr * 100,
      currency: currency || 'INR',
      status: 'demo',
      note: 'Razorpay demo mode',
    };
  }

  await notifyAllParents(
    'Fee reminder',
    `Fee payment of ₹${amountInr} is due. Open the app for payment details.`,
    'fee',
  );

  return res.json({ status: 'sent', order });
});

feesRouter.post('/attach', authRequired, feesAttachValidation, async (req, res) => {
  const { fileName, size } = req.body;
  if (!fileName) {
    return res.status(400).json({ error: 'Missing fileName' });
  }

  await ensureFeeFilesTable();

  const fileResult = await query(
    `INSERT INTO fee_files (user_id, role, file_name, file_size)
     VALUES ($1, $2, $3, $4)
     RETURNING id, file_name, file_size, created_at`,
    [req.user.sub, req.user.role, fileName, size || 0],
  );

  if (req.user.role === 'parent') {
    await notifyAllTeachers(
      'Fee proof uploaded',
      `Parent uploaded payment proof: ${fileName}`,
      'fee',
    );
  } else {
    await notifyAllParents(
      'Fee document shared',
      `School shared fee document: ${fileName}`,
      'fee',
    );
  }

  return res.json({ status: 'attached', file: fileResult.rows[0] });
});
