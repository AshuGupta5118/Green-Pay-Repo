const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth.middleware');
const { getTransactionSummary, getMonthlyTrends } = require('../controllers/analytics.controller');

// All routes require authentication
router.use(auth);

// Get transaction summary
router.get('/summary', getTransactionSummary);

// Get monthly trends
router.get('/trends', getMonthlyTrends);

module.exports = router; 