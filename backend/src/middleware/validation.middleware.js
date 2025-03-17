const { body, validationResult } = require('express-validator');

const validateRegistration = [
  body('name').trim().notEmpty().withMessage('Name is required'),
  body('email').trim().isEmail().withMessage('Invalid email address'),
  body('phone').trim().matches(/^\+?[1-9]\d{9,14}$/).withMessage('Invalid phone number'),
  body('password').isLength({ min: 6 }).withMessage('Password must be at least 6 characters long'),
  validateResults
];

const validateLogin = [
  body('email').trim().isEmail().withMessage('Invalid email address'),
  body('password').notEmpty().withMessage('Password is required'),
  validateResults
];

const validateUPI = [
  body('upiId').matches(/^[a-zA-Z0-9.\-_]{2,49}@[a-zA-Z._]{2,49}$/).withMessage('Invalid UPI ID'),
  validateResults
];

function validateResults(req, res, next) {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({
      status: 'error',
      errors: errors.array().map(err => ({
        field: err.param,
        message: err.msg
      }))
    });
  }
  next();
}

module.exports = {
  validateRegistration,
  validateLogin,
  validateUPI
}; 