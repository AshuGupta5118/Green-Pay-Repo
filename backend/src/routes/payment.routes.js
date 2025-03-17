const express = require('express');
const router = express.Router();
const { auth } = require('../middleware/auth');
const paymentController = require('../controllers/payment.controller');

// Payment routes
router.post('/initiate', auth, paymentController.initiatePayment);
router.post('/process/:paymentId', auth, paymentController.processPayment);
router.post('/upi-callback', paymentController.handleUPICallback);
router.post('/upi-deep-link', auth, paymentController.generateUPIDeepLink);

// Wallet top-up routes
router.post('/wallet/topup', auth, paymentController.initiateWalletTopup);
router.post('/wallet/confirm', auth, paymentController.confirmWalletTopup);
router.get('/wallet/history', auth, paymentController.getWalletTopupHistory);

// Money transfer routes
router.post('/transfer', auth, paymentController.transferMoney);

// Bank transfer routes
router.post('/bank-transfer', auth, paymentController.bankTransfer);
router.get('/bank-transfer/:transactionId', auth, paymentController.getBankTransferStatus);

module.exports = router; 