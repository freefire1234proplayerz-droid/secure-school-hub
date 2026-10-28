import express from 'express';

import { askAiTutor } from '../services/aiTutorService.js';
import { authRequired } from '../middleware/auth.js';
import { aiAskValidation } from '../middleware/validate.js';

export const aiRouter = express.Router();

aiRouter.post('/ask', authRequired, aiAskValidation, async (req, res) => {
  const question = req.body?.question?.toString().trim();

  if (!question) {
    return res.status(400).json({
      success: false,
      error: 'Question is required',
    });
  }

  try {
    // eslint-disable-next-line no-console
    console.log('AI Tutor question received', {
      length: question.length,
      userId: req.user.id,
      role: req.user.role,
      at: new Date().toISOString(),
    });

    const answer = await askAiTutor(question);

    return res.json({
      success: true,
      answer,
    });
  } catch (error) {
    const statusCode = error.statusCode || 500;

    // eslint-disable-next-line no-console
    console.error('AI Tutor request failed:', {
      message: error.message,
      statusCode,
      userId: req.user.id,
    });

    return res.status(statusCode).json({
      success: false,
      error:
        statusCode >= 500
          ? 'AI Tutor is temporarily unavailable. Please try again shortly.'
          : error.message,
    });
  }
});
