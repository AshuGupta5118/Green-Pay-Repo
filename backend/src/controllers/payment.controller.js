const { Transaction } = require('../models/transaction.model');
const { generateUPILink } = require('../services/upi.service');
const { validatePayment } = require('../services/payment.service');
const { User } = require('../models/user.model');
const { v4: uuidv4 } = require('uuid');

exports.initiatePayment = async (req, res) => {
  try {
    const { amount, currency, description, preferredGateway, upiProvider } = req.body;
    
    const payment = new Transaction({
      amount,
      currency,
      description,
      status: 'pending',
      gateway: preferredGateway,
      upiProvider,
      userId: req.user.id
    });

    await payment.save();
    
    res.status(201).json(payment);
  } catch (error) {
    res.status(500).json({ message: 'Error initiating payment', error: error.message });
  }
};

exports.processPayment = async (req, res) => {
  try {
    const { paymentId } = req.params;
    const payment = await Transaction.findById(paymentId);
    
    if (!payment) {
      return res.status(404).json({ message: 'Payment not found' });
    }

    payment.status = 'completed';
    await payment.save();
    
    res.json(payment);
  } catch (error) {
    res.status(500).json({ message: 'Error processing payment', error: error.message });
  }
};

exports.handleUPICallback = async (req, res) => {
  try {
    const { paymentId, txnId, status } = req.body;
    const payment = await Transaction.findById(paymentId);
    
    if (!payment) {
      return res.status(404).json({ message: 'Payment not found' });
    }

    if (status === 'SUCCESS') {
      payment.status = 'completed';
      payment.upiTransactionId = txnId;
      await payment.save();
      res.json({ success: true });
    } else {
      payment.status = 'failed';
      await payment.save();
      res.json({ success: false });
    }
  } catch (error) {
    res.status(500).json({ message: 'Error handling UPI callback', error: error.message });
  }
};

exports.generateUPIDeepLink = async (req, res) => {
  try {
    const { paymentId, provider, upiId } = req.body;
    const payment = await Transaction.findById(paymentId);
    
    if (!payment) {
      return res.status(404).json({ message: 'Payment not found' });
    }

    const deepLink = await generateUPILink({
      amount: payment.amount,
      upiId,
      provider,
      paymentId: payment.id
    });
    
    res.json({ deepLink });
  } catch (error) {
    res.status(500).json({ message: 'Error generating UPI deep link', error: error.message });
  }
};

// Wallet top-up controller methods
exports.initiateWalletTopup = async (req, res) => {
  try {
    const { amount, method, gateway, upiProvider } = req.body;
    
    // Validate amount
    if (!amount || amount <= 0) {
      return res.status(400).json({ message: 'Invalid amount' });
    }
    
    // Create a wallet top-up transaction
    const topupTransaction = new Transaction({
      id: uuidv4(),
      amount,
      currency: 'INR',
      description: 'Wallet top-up',
      status: 'pending',
      type: 'wallet_topup',
      gateway,
      upiProvider,
      userId: req.user.id,
      metadata: {
        method,
        initiatedAt: new Date().toISOString()
      }
    });

    await topupTransaction.save();
    
    res.status(201).json({ 
      success: true,
      paymentId: topupTransaction.id,
      amount,
      status: 'pending'
    });
  } catch (error) {
    res.status(500).json({ message: 'Error initiating wallet top-up', error: error.message });
  }
};

exports.confirmWalletTopup = async (req, res) => {
  try {
    const { paymentId, gatewayPaymentId, status } = req.body;
    
    // Find the top-up transaction
    const topupTransaction = await Transaction.findOne({ 
      id: paymentId,
      userId: req.user.id
    });
    
    if (!topupTransaction) {
      return res.status(404).json({ message: 'Top-up transaction not found' });
    }
    
    // Update transaction status
    topupTransaction.status = status;
    topupTransaction.gatewayPaymentId = gatewayPaymentId;
    topupTransaction.metadata = {
      ...topupTransaction.metadata,
      confirmedAt: new Date().toISOString()
    };
    
    await topupTransaction.save();
    
    // If payment was successful, update user's wallet balance
    if (status === 'completed') {
      const user = await User.findById(req.user.id);
      
      if (!user) {
        return res.status(404).json({ message: 'User not found' });
      }
      
      // Update wallet balance
      user.walletBalance = (user.walletBalance || 0) + topupTransaction.amount;
      await user.save();
      
      // Create a credit transaction
      const creditTransaction = new Transaction({
        id: uuidv4(),
        amount: topupTransaction.amount,
        currency: 'INR',
        description: `Wallet top-up via ${topupTransaction.metadata.method}`,
        status: 'completed',
        type: 'credit',
        userId: req.user.id,
        metadata: {
          topupId: topupTransaction.id,
          method: topupTransaction.metadata.method
        }
      });
      
      await creditTransaction.save();
    }
    
    res.json({ 
      success: true,
      status: topupTransaction.status,
      paymentId: topupTransaction.id
    });
  } catch (error) {
    res.status(500).json({ message: 'Error confirming wallet top-up', error: error.message });
  }
};

exports.getWalletTopupHistory = async (req, res) => {
  try {
    const { limit = 10, skip = 0 } = req.query;
    
    // Find all wallet top-up transactions for the user
    const topupTransactions = await Transaction.find({
      userId: req.user.id,
      type: 'wallet_topup'
    })
    .sort({ createdAt: -1 })
    .skip(parseInt(skip))
    .limit(parseInt(limit));
    
    // Get total count
    const total = await Transaction.countDocuments({
      userId: req.user.id,
      type: 'wallet_topup'
    });
    
    res.json({
      success: true,
      data: topupTransactions,
      pagination: {
        total,
        limit: parseInt(limit),
        skip: parseInt(skip)
      }
    });
  } catch (error) {
    res.status(500).json({ message: 'Error fetching wallet top-up history', error: error.message });
  }
};

// Money transfer controller method
exports.transferMoney = async (req, res) => {
  try {
    const { recipientId, amount, note } = req.body;
    
    // Validate amount
    if (!amount || amount <= 0) {
      return res.status(400).json({ message: 'Invalid amount' });
    }
    
    // Find sender (current user)
    const sender = await User.findById(req.user.id);
    if (!sender) {
      return res.status(404).json({ message: 'Sender not found' });
    }
    
    // Check if sender has sufficient balance
    if (!sender.walletBalance || sender.walletBalance < amount) {
      return res.status(400).json({ message: 'Insufficient balance' });
    }
    
    // Find recipient
    const recipient = await User.findById(recipientId);
    if (!recipient) {
      return res.status(404).json({ message: 'Recipient not found' });
    }
    
    // Generate transaction ID
    const transactionId = uuidv4();
    
    // Create debit transaction for sender
    const senderTransaction = new Transaction({
      id: transactionId,
      amount,
      currency: 'INR',
      description: note || 'Money transfer',
      status: 'completed',
      type: 'debit',
      userId: req.user.id,
      receiver: recipientId,
      metadata: {
        transferType: 'wallet_transfer',
        recipientName: recipient.name,
        note: note || 'Money transfer'
      }
    });
    
    // Create credit transaction for recipient
    const recipientTransaction = new Transaction({
      id: uuidv4(),
      amount,
      currency: 'INR',
      description: note || 'Money received',
      status: 'completed',
      type: 'credit',
      userId: recipientId,
      sender: req.user.id,
      metadata: {
        transferType: 'wallet_transfer',
        senderName: sender.name,
        originalTransactionId: transactionId,
        note: note || 'Money received'
      }
    });
    
    // Update wallet balances
    sender.walletBalance -= amount;
    recipient.walletBalance = (recipient.walletBalance || 0) + amount;
    
    // Save all changes in a transaction
    await Promise.all([
      senderTransaction.save(),
      recipientTransaction.save(),
      sender.save(),
      recipient.save()
    ]);
    
    res.status(200).json({
      success: true,
      message: 'Money transferred successfully',
      transactionId,
      amount,
      status: 'completed'
    });
  } catch (error) {
    res.status(500).json({ message: 'Error transferring money', error: error.message });
  }
};

// Bank transfer controller methods
exports.bankTransfer = async (req, res) => {
  try {
    const { bankName, accountNumber, ifscCode, accountHolderName, amount, note } = req.body;
    
    // Validate required fields
    if (!bankName || !accountNumber || !ifscCode || !accountHolderName) {
      return res.status(400).json({ message: 'Missing required bank details' });
    }
    
    // Validate amount
    if (!amount || amount <= 0) {
      return res.status(400).json({ message: 'Invalid amount' });
    }
    
    // Find user
    const user = await User.findById(req.user.id);
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }
    
    // Check if user has sufficient balance
    if (!user.walletBalance || user.walletBalance < amount) {
      return res.status(400).json({ message: 'Insufficient balance' });
    }
    
    // Generate transaction ID
    const transactionId = uuidv4();
    
    // Create bank transfer transaction
    const bankTransferTransaction = new Transaction({
      id: transactionId,
      amount,
      currency: 'INR',
      description: note || 'Bank transfer',
      status: 'initiated',
      type: 'bank_transfer',
      userId: req.user.id,
      metadata: {
        bankName,
        accountNumber,
        ifscCode,
        accountHolderName,
        initiatedAt: new Date().toISOString()
      }
    });
    
    // Deduct amount from user's wallet
    user.walletBalance -= amount;
    
    // Save transaction and update user balance
    await Promise.all([
      bankTransferTransaction.save(),
      user.save()
    ]);
    
    // In a real-world scenario, you would integrate with a banking API here
    // For now, we'll simulate the process
    
    // Schedule a job to process the transfer (simulated)
    setTimeout(async () => {
      try {
        // Update transaction status to processing
        bankTransferTransaction.status = 'processing';
        await bankTransferTransaction.save();
        
        // After some time, complete the transfer (in a real app, this would be based on bank API callback)
        setTimeout(async () => {
          try {
            bankTransferTransaction.status = 'completed';
            bankTransferTransaction.metadata = {
              ...bankTransferTransaction.metadata,
              completedAt: new Date().toISOString()
            };
            await bankTransferTransaction.save();
          } catch (error) {
            console.error('Error completing bank transfer:', error);
          }
        }, 60000); // Simulate completion after 1 minute
      } catch (error) {
        console.error('Error processing bank transfer:', error);
      }
    }, 5000); // Simulate processing after 5 seconds
    
    res.status(200).json({
      success: true,
      message: 'Bank transfer initiated',
      transactionId,
      status: 'initiated',
      amount
    });
  } catch (error) {
    res.status(500).json({ message: 'Error initiating bank transfer', error: error.message });
  }
};

exports.getBankTransferStatus = async (req, res) => {
  try {
    const { transactionId } = req.params;
    
    // Find the bank transfer transaction
    const transaction = await Transaction.findOne({
      id: transactionId,
      userId: req.user.id,
      type: 'bank_transfer'
    });
    
    if (!transaction) {
      return res.status(404).json({ message: 'Bank transfer transaction not found' });
    }
    
    res.json({
      success: true,
      transactionId,
      status: transaction.status,
      amount: transaction.amount,
      metadata: transaction.metadata,
      createdAt: transaction.createdAt,
      updatedAt: transaction.updatedAt
    });
  } catch (error) {
    res.status(500).json({ message: 'Error getting bank transfer status', error: error.message });
  }
}; 