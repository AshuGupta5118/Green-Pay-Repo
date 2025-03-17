const mongoose = require('mongoose');

const transactionSchema = new mongoose.Schema({
  id: {
    type: String,
    required: true,
    unique: true
  },
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  sender: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User'
  },
  receiver: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User'
  },
  amount: {
    type: Number,
    required: true,
    min: 0.01
  },
  currency: {
    type: String,
    default: 'INR',
    required: true
  },
  type: {
    type: String,
    enum: ['UPI', 'WALLET', 'credit', 'debit', 'wallet_topup', 'bank_transfer'],
    required: true
  },
  status: {
    type: String,
    enum: ['pending', 'initiated', 'processing', 'completed', 'failed', 'cancelled', 'refunded'],
    default: 'pending'
  },
  gateway: {
    type: String,
    enum: ['razorpay', 'stripe', 'upi', null],
    default: null
  },
  upiProvider: {
    type: String,
    enum: ['googlePay', 'phonePe', 'paytm', 'bhim', 'other', null],
    default: null
  },
  upiTransactionId: {
    type: String,
    sparse: true
  },
  gatewayPaymentId: {
    type: String,
    sparse: true
  },
  description: {
    type: String,
    trim: true
  },
  metadata: {
    type: Map,
    of: mongoose.Schema.Types.Mixed,
    default: {}
  }
}, {
  timestamps: true
});

// Index for faster queries
transactionSchema.index({ userId: 1, createdAt: -1 });
transactionSchema.index({ sender: 1, createdAt: -1 });
transactionSchema.index({ receiver: 1, createdAt: -1 });
transactionSchema.index({ status: 1 });
transactionSchema.index({ type: 1 });
transactionSchema.index({ upiTransactionId: 1 }, { sparse: true });
transactionSchema.index({ gatewayPaymentId: 1 }, { sparse: true });
transactionSchema.index({ id: 1 }, { unique: true });

const Transaction = mongoose.model('Transaction', transactionSchema);

module.exports = { Transaction }; 