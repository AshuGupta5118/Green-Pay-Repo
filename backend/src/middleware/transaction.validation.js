const { body, param } = require('express-validator');
const { validateResults } = require('./validation.middleware');

const validateCreateTransaction = [
  body('receiverUPI').matches(/^[a-zA-Z0-9.\-_]{2,49}@[a-zA-Z._]{2,49}$/).withMessage('Invalid receiver UPI ID'),
  body('amount').isFloat({ min: 1 }).withMessage('Amount must be greater than 0'),
  body('type').isIn(['UPI', 'WALLET']).withMessage('Invalid transaction type'),
  body('description').optional().trim().isLength({ max: 100 }).withMessage('Description too long'),
  validateResults
];

const validateTransactionStatus = [
  param('transactionId').isMongoId().withMessage('Invalid transaction ID'),
  body('status').isIn(['SUCCESS', 'FAILED']).withMessage('Invalid status'),
  body('upiTransactionId').optional().isString().withMessage('Invalid UPI transaction ID'),
  body('bankReferenceNumber').optional().isString().withMessage('Invalid bank reference number'),
  validateResults
];

module.exports = {
  validateCreateTransaction,
  validateTransactionStatus
}; 