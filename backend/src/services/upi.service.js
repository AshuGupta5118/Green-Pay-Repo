const crypto = require('crypto');

class UPIService {
  constructor() {
    this.merchantId = process.env.UPI_MERCHANT_ID;
    this.merchantName = process.env.UPI_MERCHANT_NAME;
  }

  generateTransactionId() {
    return `GP${Date.now()}${crypto.randomBytes(4).toString('hex')}`;
  }

  generateDeepLink(transaction) {
    const params = new URLSearchParams({
      pa: transaction.metadata.receiverUPI, // Payee UPI ID
      pn: transaction.receiver.name, // Payee Name
      tn: transaction.description || 'Green Pay Transfer', // Transaction Note
      am: transaction.amount.toString(), // Amount
      tr: transaction.upiTransactionId || this.generateTransactionId(), // Transaction Reference
      cu: 'INR', // Currency
      mc: this.merchantId || '', // Merchant Code (optional)
      mid: this.merchantId || '', // Merchant ID (optional)
      mn: this.merchantName || '', // Merchant Name (optional)
    });

    return `upi://pay?${params.toString()}`;
  }

  parseCallbackURL(url) {
    const params = new URLSearchParams(url.split('?')[1]);
    return {
      transactionId: params.get('tr'),
      status: params.get('Status').toUpperCase(),
      responseCode: params.get('responseCode'),
      approvalRefNo: params.get('ApprovalRefNo'),
      txnRef: params.get('txnRef')
    };
  }

  validateCallback(data) {
    // Add validation logic based on your UPI provider's requirements
    const requiredParams = ['tr', 'Status', 'responseCode'];
    return requiredParams.every(param => data.hasOwnProperty(param));
  }
}

const generateUPILink = async ({ amount, upiId, provider, paymentId }) => {
  const params = new URLSearchParams({
    pa: upiId, // Payee VPA/UPI ID
    pn: process.env.MERCHANT_NAME || 'Green Pay',
    am: amount.toFixed(2),
    cu: 'INR',
    tn: `Payment ID: ${paymentId}`,
  });

  return `upi://pay?${params.toString()}`;
};

module.exports = {
  generateUPILink,
  UPIService,
}; 