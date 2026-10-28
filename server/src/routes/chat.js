import express from 'express';
import { authRequired } from '../middleware/auth.js';
import { query } from '../db.js';
import { encryptMessage, decryptMessage } from '../utils/crypto.js';
import { notifyAllParents, notifyAllTeachers } from '../utils/notify.js';
import { chatSendValidation } from '../middleware/validate.js';

export const chatRouter = express.Router();

chatRouter.post('/send', authRequired, chatSendValidation, async (req, res) => {
  const { message } = req.body;
  if (!message) {
    return res.status(400).json({ error: 'Missing message' });
  }

  const cipher = encryptMessage(message);
  const result = await query(
    `INSERT INTO messages (sender_id, body_enc, created_at)
     VALUES ($1, $2, NOW())
     RETURNING id, sender_id, created_at`,
    [req.user.sub, cipher],
  );

  const preview = message.length > 80 ? `${message.slice(0, 77)}...` : message;
  if (req.user.role === 'parent') {
    await notifyAllTeachers('New parent message', preview, 'chat');
  } else {
    await notifyAllParents('New teacher message', preview, 'chat');
  }

  return res.json({
    status: 'sent',
    message: {
      id: result.rows[0].id,
      senderId: result.rows[0].sender_id,
      senderRole: req.user.role,
      body: message,
      createdAt: result.rows[0].created_at,
    },
  });
});

chatRouter.get('/history', authRequired, async (req, res) => {
  const result = await query(
    `SELECT m.sender_id, m.body_enc, m.created_at, u.role AS sender_role, u.email AS sender_email
     FROM messages m
     JOIN users u ON u.id = m.sender_id
     ORDER BY m.created_at ASC
     LIMIT 100`,
    [],
  );

  const messages = result.rows.map((row) => ({
    senderId: row.sender_id,
    senderRole: row.sender_role,
    senderEmail: row.sender_email,
    body: decryptMessage(row.body_enc),
    createdAt: row.created_at,
  }));

  return res.json({ messages });
});
