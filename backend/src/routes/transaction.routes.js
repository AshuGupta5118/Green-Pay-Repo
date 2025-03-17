const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth.middleware');
const { validateCreateTransaction, validateTransactionStatus } = require('../middleware/transaction.validation');
const { createTransaction, updateTransactionStatus, getTransactionHistory } = require('../controllers/transaction.controller');

// All routes require authentication
router.use(auth);

// Create new transaction
router.post('/', validateCreateTransaction, createTransaction);

// Update transaction status (UPI callback)
router.patch('/:transactionId/status', validateTransactionStatus, updateTransactionStatus);

// Get transaction history
router.get('/history', getTransactionHistory);

module.exports = router; 