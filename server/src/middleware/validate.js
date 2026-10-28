import { body, param, query, validationResult } from 'express-validator';

export function validateRequest(req, res, next) {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ error: 'Validation failed', details: errors.array() });
  }
  next();
}

export const signupValidation = [
  body('email').isEmail().normalizeEmail().withMessage('Valid email required'),
  body('password').isLength({ min: 8 }).withMessage('Password must be at least 8 characters'),
  body('role').isIn(['student', 'teacher', 'parent', 'admin']).withMessage('Invalid role'),
  validateRequest,
];

export const loginValidation = [
  body('email').isEmail().normalizeEmail().withMessage('Valid email required'),
  body('password').notEmpty().withMessage('Password required'),
  body('role').optional().isIn(['student', 'teacher', 'parent', 'admin']).withMessage('Invalid role'),
  validateRequest,
];

export const loginOtpValidation = [
  body('email').isEmail().normalizeEmail().withMessage('Valid email required'),
  body('password').notEmpty().withMessage('Password required'),
  body('role').isIn(['student', 'teacher', 'parent', 'admin']).withMessage('Invalid role'),
  validateRequest,
];

export const verifyOtpValidation = [
  body('otp').isLength({ min: 6, max: 6 }).isNumeric().withMessage('6-digit OTP required'),
  body('tempUserId').isInt({ min: 1 }).withMessage('Valid tempUserId required'),
  validateRequest,
];

export const attendanceMarkValidation = [
  body('qr').notEmpty().withMessage('QR data required'),
  validateRequest,
];

export const homeworkCreateValidation = [
  body('title').trim().isLength({ min: 1, max: 200 }).withMessage('Title required (max 200 chars)'),
  body('description').optional().trim().isLength({ max: 2000 }).withMessage('Description too long'),
  validateRequest,
];

export const homeworkAttachValidation = [
  body('fileName').trim().isLength({ min: 1, max: 255 }).withMessage('File name required'),
  body('size').optional().isInt({ min: 0 }).withMessage('Size must be a positive integer'),
  body('title').optional().trim().isLength({ max: 200 }).withMessage('Title too long'),
  validateRequest,
];

export const feesRemindValidation = [
  body('amount').optional().isInt({ min: 1, max: 1000000 }).withMessage('Amount must be 1-1,000,000'),
  body('currency').optional().isIn(['INR']).withMessage('Currency must be INR'),
  validateRequest,
];

export const feesAttachValidation = [
  body('fileName').trim().isLength({ min: 1, max: 255 }).withMessage('File name required'),
  body('size').optional().isInt({ min: 0 }).withMessage('Size must be a positive integer'),
  validateRequest,
];

export const chatSendValidation = [
  body('message').trim().isLength({ min: 1, max: 5000 }).withMessage('Message required (max 5000 chars)'),
  validateRequest,
];

export const aiAskValidation = [
  body('question').trim().isLength({ min: 1, max: 2000 }).withMessage('Question required (max 2000 chars)'),
  validateRequest,
];

export const securityScanValidation = [
  body('target').isIn(['127.0.0.1', 'localhost']).withMessage('Target not allowed'),
  validateRequest,
];

export const adminUserCreateValidation = [
  body('email').isEmail().normalizeEmail().withMessage('Valid email required'),
  body('password').isLength({ min: 8 }).withMessage('Password must be at least 8 characters'),
  body('role').isIn(['student', 'teacher', 'parent', 'admin']).withMessage('Invalid role'),
  body('firstName').optional().trim().isLength({ max: 100 }).withMessage('First name too long'),
  body('lastName').optional().trim().isLength({ max: 100 }).withMessage('Last name too long'),
  body('phone').optional().trim().isLength({ max: 20 }).withMessage('Phone too long'),
  body('grade').optional().isInt({ min: 1, max: 12 }).withMessage('Grade must be 1-12'),
  body('section').optional().trim().isLength({ max: 2 }).withMessage('Section too long'),
  body('rollNo').optional().trim().isLength({ max: 20 }).withMessage('Roll number too long'),
  body('parentUserId').optional().isInt({ min: 1 }).withMessage('Invalid parent user ID'),
  validateRequest,
];

export const adminUserStatusValidation = [
  param('id').isInt({ min: 1 }).withMessage('Valid user ID required'),
  body('status').isIn(['active', 'disabled']).withMessage('Status must be active or disabled'),
  validateRequest,
];

export const adminPasswordResetValidation = [
  param('id').isInt({ min: 1 }).withMessage('Valid user ID required'),
  body('password').isLength({ min: 8 }).withMessage('Password must be at least 8 characters'),
  validateRequest,
];

export const adminUsersQueryValidation = [
  query('role').optional().isIn(['student', 'teacher', 'parent', 'admin', 'all']).withMessage('Invalid role filter'),
  query('status').optional().isIn(['active', 'disabled', 'all']).withMessage('Invalid status filter'),
  query('class').optional().trim().isLength({ max: 50 }).withMessage('Class filter too long'),
  query('search').optional().trim().isLength({ max: 100 }).withMessage('Search query too long'),
  validateRequest,
];

export const auditLogsQueryValidation = [
  query('category').optional().trim().isLength({ max: 50 }).withMessage('Category filter too long'),
  validateRequest,
];