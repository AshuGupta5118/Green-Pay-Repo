const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth.middleware');
const { validateRegistration, validateLogin, validateUPI } = require('../middleware/validation.middleware');
const { register, login, getProfile, updateProfile } = require('../controllers/user.controller');

// Public routes
router.post('/register', validateRegistration, register);
router.post('/login', validateLogin, login);

// Protected routes
router.get('/profile', auth, getProfile);
router.patch('/profile', auth, validateUPI, updateProfile);

module.exports = router; 