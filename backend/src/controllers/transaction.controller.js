const Transaction = require('../models/transaction.model');
const User = require('../models/user.model');
const mongoose = require('mongoose');

// Create new transaction
const createTransaction = async (req, res) => {
  const session = await mongoose.startSession();
  session.startTransaction();

  try {
    const { receiverUPI, amount, type, description } = req.body;
    const sender = req.user;

    // Find receiver by UPI ID
    const receiver = await User.findOne({ upiId: receiverUPI });
    if (!receiver) {
      return res.status(404).json({
        status: 'error',
        message: 'Receiver UPI ID not found'
      });
    }

    // Prevent self-transfer
    if (sender._id.equals(receiver._id)) {
      return res.status(400).json({
        status: 'error',
        message: 'Cannot transfer to self'
      });
    }

    // Check sender's balance for wallet transfers
    if (type === 'WALLET' && sender.balance < amount) {
      return res.status(400).json({
        status: 'error',
        message: 'Insufficient balance'
      });
    }

    // Create transaction
    const transaction = new Transaction({
      sender: sender._id,
      receiver: receiver._id,
      amount,
      type,
      description,
      metadata: {
        senderUPI: sender.upiId,
        receiverUPI: receiver.upiId
      }
    });

    // For wallet transfers, update balances immediately
    if (type === 'WALLET') {
      sender.balance -= amount;
      receiver.balance += amount;
      transaction.status = 'SUCCESS';
      
      await sender.save({ session });
      await receiver.save({ session });
    }

    await transaction.save({ session });
    await session.commitTransaction();

    res.status(201).json({
      status: 'success',
      data: {
        transaction: {
          id: transaction._id,
          amount,
          type,
          status: transaction.status,
          description,
          createdAt: transaction.createdAt
        }
      }
    });
  } catch (error) {
    await session.abortTransaction();
    res.status(500).json({
      status: 'error',
      message: 'Error processing transaction'
    });
  } finally {
    session.endSession();
  }
};

// Update transaction status (for UPI callbacks)
const updateTransactionStatus = async (req, res) => {
  const session = await mongoose.startSession();
  session.startTransaction();

  try {
    const { transactionId } = req.params;
    const { status, upiTransactionId, bankReferenceNumber } = req.body;

    const transaction = await Transaction.findById(transactionId);
    if (!transaction) {
      return res.status(404).json({
        status: 'error',
        message: 'Transaction not found'
      });
    }

    if (transaction.status !== 'PENDING') {
      return res.status(400).json({
        status: 'error',
        message: 'Transaction already processed'
      });
    }

    transaction.status = status;
    transaction.upiTransactionId = upiTransactionId;
    transaction.metadata.bankReferenceNumber = bankReferenceNumber;

    // If successful UPI transaction, update balances
    if (status === 'SUCCESS' && transaction.type === 'UPI') {
      const sender = await User.findById(transaction.sender);
      const receiver = await User.findById(transaction.receiver);

      sender.balance -= transaction.amount;
      receiver.balance += transaction.amount;

      await sender.save({ session });
      await receiver.save({ session });
    }

    await transaction.save({ session });
    await session.commitTransaction();

    res.json({
      status: 'success',
      data: {
        transaction: {
          id: transaction._id,
          status: transaction.status,
          upiTransactionId: transaction.upiTransactionId
        }
      }
    });
  } catch (error) {
    await session.abortTransaction();
    res.status(500).json({
      status: 'error',
      message: 'Error updating transaction'
    });
  } finally {
    session.endSession();
  }
};

// Get transaction history
const getTransactionHistory = async (req, res) => {
  try {
    const { type, status, startDate, endDate, limit = 10, page = 1 } = req.query;
    const query = {
      $or: [
        { sender: req.user._id },
        { receiver: req.user._id }
      ]
    };

    // Apply filters
    if (type) query.type = type;
    if (status) query.status = status;
    if (startDate || endDate) {
      query.createdAt = {};
      if (startDate) query.createdAt.$gte = new Date(startDate);
      if (endDate) query.createdAt.$lte = new Date(endDate);
    }

    const skip = (page - 1) * limit;
    
    // Get transactions with populated user details
    const transactions = await Transaction.find(query)
      .populate('sender', 'name email upiId')
      .populate('receiver', 'name email upiId')
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(parseInt(limit));

    // Get total count for pagination
    const total = await Transaction.countDocuments(query);

    res.json({
      status: 'success',
      data: {
        transactions: transactions.map(t => ({
          id: t._id,
          amount: t.amount,
          type: t.type,
          status: t.status,
          description: t.description,
          sender: {
            name: t.sender.name,
            upiId: t.sender.upiId
          },
          receiver: {
            name: t.receiver.name,
            upiId: t.receiver.upiId
          },
          createdAt: t.createdAt
        })),
        pagination: {
          total,
          page: parseInt(page),
          pages: Math.ceil(total / limit)
        }
      }
    });
  } catch (error) {
    res.status(500).json({
      status: 'error',
      message: 'Error fetching transactions'
    });
  }
};

module.exports = {
  createTransaction,
  updateTransactionStatus,
  getTransactionHistory
}; 