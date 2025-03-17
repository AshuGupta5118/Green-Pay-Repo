import 'dart:async';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/transaction.dart';
import 'api_service.dart';
import 'database_service.dart';
import 'security_service.dart';
import 'wallet_service.dart';

enum PaymentStatus {
  pending,
  processing,
  completed,
  failed,
  refunded,
  cancelled
}

enum PaymentGateway { razorpay, stripe, upi }

enum UPIProvider { googlePay, phonePe, paytm, bhim, other }

class PaymentGatewayConfig {
  final String apiKey;
  final String merchantId;
  final String callbackUrl;
  final Map<String, dynamic>? additionalConfig;

  const PaymentGatewayConfig({
    required this.apiKey,
    required this.merchantId,
    required this.callbackUrl,
    this.additionalConfig,
  });
}

class PaymentDetails {
  final String id;
  final double amount;
  final String currency;
  final String description;
  final PaymentStatus status;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;
  final PaymentGateway? gateway;
  final String? gatewayPaymentId;
  final String? upiTransactionId;
  final UPIProvider? upiProvider;

  const PaymentDetails({
    required this.id,
    required this.amount,
    required this.currency,
    required this.description,
    required this.status,
    required this.timestamp,
    this.metadata,
    this.gateway,
    this.gatewayPaymentId,
    this.upiTransactionId,
    this.upiProvider,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'amount': amount,
        'currency': currency,
        'description': description,
        'status': status.toString().split('.').last,
        'timestamp': timestamp.toIso8601String(),
        'metadata': metadata,
        'gateway': gateway?.toString().split('.').last,
        'gatewayPaymentId': gatewayPaymentId,
        'upiTransactionId': upiTransactionId,
        'upiProvider': upiProvider?.toString().split('.').last,
      };

  factory PaymentDetails.fromJson(Map<String, dynamic> json) => PaymentDetails(
        id: json['id'],
        amount: json['amount'].toDouble(),
        currency: json['currency'],
        description: json['description'],
        status: PaymentStatus.values.firstWhere(
          (e) => e.toString().split('.').last == json['status'],
          orElse: () => PaymentStatus.pending,
        ),
        timestamp: DateTime.parse(json['timestamp']),
        metadata: json['metadata'] as Map<String, dynamic>?,
        gateway: json['gateway'] == null
            ? null
            : PaymentGateway.values.firstWhere(
                (e) => e.toString().split('.').last == json['gateway'],
              ),
        gatewayPaymentId: json['gatewayPaymentId'],
        upiTransactionId: json['upiTransactionId'],
        upiProvider: json['upiProvider'] == null
            ? null
            : UPIProvider.values.firstWhere(
                (e) => e.toString().split('.').last == json['upiProvider'],
              ),
      );
}

class PaymentResult {
  final bool success;
  final String? message;
  final PaymentDetails? details;

  const PaymentResult({
    required this.success,
    this.message,
    this.details,
  });
}

class PaymentService {
  static const _storage = FlutterSecureStorage();

  static const _pendingPaymentsKey = 'pending_payments';
  static const _maxRetries = 3;
  static const _retryDelay = Duration(seconds: 2);

  final _apiService = APIService();
  final _databaseService = DatabaseService();
  final _securityService = SecurityService();
  final _paymentConfigs = <PaymentGateway, PaymentGatewayConfig>{};
  final _statusUpdateControllers = <String, StreamController<PaymentDetails>>{};

  // Singleton instance
  static final PaymentService _instance = PaymentService._internal();
  factory PaymentService() => _instance;
  PaymentService._internal();

  Future<void> initialize() async {
    await _securityService.initialize();
    await _loadPaymentConfigs();
  }

  Future<void> _loadPaymentConfigs() async {
    try {
      final response = await _apiService.get('${APIEndpoints.payments}/config');
      for (final entry in response['gateways'].entries) {
        final gateway = PaymentGateway.values.firstWhere(
          (g) => g.toString().split('.').last == entry.key,
        );
        final config = entry.value as Map<String, dynamic>;
        _paymentConfigs[gateway] = PaymentGatewayConfig(
          apiKey: config['apiKey'],
          merchantId: config['merchantId'],
          callbackUrl: config['callbackUrl'],
          additionalConfig: config['additionalConfig'],
        );
      }
    } catch (e) {
      throw Exception('Failed to load payment configurations: $e');
    }
  }

  Future<PaymentDetails> initiatePayment({
    required double amount,
    required String currency,
    required String description,
    PaymentGateway? preferredGateway,
    UPIProvider? upiProvider,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final gateway = preferredGateway ?? PaymentGateway.upi;
      final config = _paymentConfigs[gateway];
      if (config == null) {
        throw Exception('Payment gateway not configured: $gateway');
      }

      // Create payment intent with gateway
      final response = await _apiService.post(
        '${APIEndpoints.payments}/initiate',
        {
          'amount': amount,
          'currency': currency,
          'description': description,
          'gateway': gateway.toString().split('.').last,
          if (upiProvider != null)
            'upiProvider': upiProvider.toString().split('.').last,
          'metadata': metadata,
        },
      );

      final payment = PaymentDetails.fromJson(response);
      await _storePendingPayment(payment);

      // Start listening for status updates
      _startStatusUpdates(payment.id);

      return payment;
    } catch (e) {
      throw Exception('Failed to initiate payment: $e');
    }
  }

  void _startStatusUpdates(String paymentId) {
    final controller = StreamController<PaymentDetails>.broadcast();
    _statusUpdateControllers[paymentId] = controller;

    Timer.periodic(const Duration(seconds: 5), (timer) async {
      try {
        final status = await updatePaymentStatus(paymentId);
        if (!controller.isClosed) {
          controller.add(status);
        }
        if (status.status.index >= PaymentStatus.completed.index) {
          timer.cancel();
          await controller.close();
          _statusUpdateControllers.remove(paymentId);
        }
      } catch (e) {
        print('Error updating payment status: $e');
      }
    });
  }

  Stream<PaymentDetails> getPaymentUpdates(String paymentId) {
    return _statusUpdateControllers[paymentId]?.stream ??
        Stream.fromFuture(getPaymentStatus(paymentId).then((payment) {
          if (payment == null) {
            throw Exception('Payment not found');
          }
          return payment;
        }));
  }

  Future<T> _withRetry<T>(Future<T> Function() operation) async {
    int attempts = 0;
    while (true) {
      try {
        attempts++;
        return await operation();
      } catch (e) {
        if (attempts >= _maxRetries) rethrow;
        await Future.delayed(_retryDelay * attempts);
      }
    }
  }

  Future<PaymentDetails> processPayment(String paymentId) async {
    try {
      final payment = await _getPendingPayment(paymentId);
      if (payment == null) {
        throw Exception('Payment not found');
      }

      // Here you would integrate with your actual payment gateway
      // For now, we'll simulate a successful payment
      final processedPayment = PaymentDetails(
        id: payment.id,
        amount: payment.amount,
        currency: payment.currency,
        description: payment.description,
        status: PaymentStatus.completed,
        timestamp: DateTime.now(),
        metadata: payment.metadata,
        gateway: payment.gateway,
        gatewayPaymentId: payment.gatewayPaymentId,
        upiTransactionId: payment.upiTransactionId,
        upiProvider: payment.upiProvider,
      );

      // Create transaction record for completed payment
      await _createTransaction(processedPayment);

      // Remove from pending payments
      await _removePendingPayment(payment.id);
      return processedPayment;
    } catch (e) {
      throw Exception('Failed to process payment: $e');
    }
  }

  Future<PaymentDetails?> getPaymentStatus(String paymentId) async {
    try {
      return await _getPendingPayment(paymentId);
    } catch (e) {
      throw Exception('Failed to get payment status: $e');
    }
  }

  Future<void> _storePendingPayment(PaymentDetails payment) async {
    try {
      final payments = await _loadPendingPayments();
      payments[payment.id] = payment;
      await _savePendingPayments(payments);
    } catch (e) {
      throw Exception('Failed to store pending payment: $e');
    }
  }

  Future<PaymentDetails?> _getPendingPayment(String paymentId) async {
    try {
      final payments = await _loadPendingPayments();
      return payments[paymentId];
    } catch (e) {
      throw Exception('Failed to get pending payment: $e');
    }
  }

  Future<void> _removePendingPayment(String paymentId) async {
    try {
      final payments = await _loadPendingPayments();
      payments.remove(paymentId);
      await _savePendingPayments(payments);
    } catch (e) {
      throw Exception('Failed to remove pending payment: $e');
    }
  }

  Future<Map<String, PaymentDetails>> _loadPendingPayments() async {
    try {
      final encryptedData = await _storage.read(key: _pendingPaymentsKey);
      if (encryptedData == null) return {};

      final decryptedData = _securityService.decrypt(encryptedData);
      final jsonData = json.decode(decryptedData) as Map<String, dynamic>;

      return Map.fromEntries(
        jsonData.entries.map((e) => MapEntry(
              e.key,
              PaymentDetails.fromJson(e.value as Map<String, dynamic>),
            )),
      );
    } catch (e) {
      throw Exception('Failed to load pending payments: $e');
    }
  }

  Future<void> _savePendingPayments(
      Map<String, PaymentDetails> payments) async {
    try {
      final jsonData = json.encode(
        Map.fromEntries(
          payments.entries.map((e) => MapEntry(e.key, e.value.toJson())),
        ),
      );

      final encryptedData = _securityService.encrypt(jsonData);
      await _storage.write(key: _pendingPaymentsKey, value: encryptedData);
    } catch (e) {
      throw Exception('Failed to save pending payments: $e');
    }
  }

  Future<void> _createTransaction(PaymentDetails payment) async {
    final transaction = Transaction(
      id: payment.id,
      title: payment.description,
      amount: payment.amount,
      timestamp: payment.timestamp,
      type: TransactionType.debit,
      category: TransactionCategory.others,
      upiId: '',
      description: 'Payment',
      payeeId: '',
    );

    await _databaseService.addTransaction(transaction);
  }

  Future<bool> cancelPayment(String paymentId) async {
    try {
      final payment = await getPaymentStatus(paymentId);
      if (payment == null) {
        throw Exception('Payment not found');
      }

      if (payment.status == PaymentStatus.completed ||
          payment.status == PaymentStatus.refunded) {
        throw Exception('Cannot cancel completed or refunded payment');
      }

      // Call payment gateway API to cancel payment
      final response = await _apiService.post(
        '${APIEndpoints.payments}/cancel',
        {'paymentId': paymentId},
      );

      final updatedPayment = PaymentDetails.fromJson(response);
      if (updatedPayment.status == PaymentStatus.cancelled) {
        // Create cancellation transaction if needed
        if (payment.status == PaymentStatus.processing) {
          final cancelTransaction = Transaction(
            id: '${paymentId}_cancel',
            title: 'Cancelled: ${payment.description}',
            amount: payment.amount,
            timestamp: DateTime.now(),
            type: TransactionType.credit,
            category: TransactionCategory.others,
            upiId: '',
            description: 'Payment Cancelled',
            payeeId: '',
          );
          await _databaseService.addTransaction(cancelTransaction);
        }

        await _removePendingPayment(paymentId);
        return true;
      }
      return false;
    } catch (e) {
      throw Exception('Failed to cancel payment: $e');
    }
  }

  Future<bool> refundPayment(String paymentId) async {
    try {
      final payment = await getPaymentStatus(paymentId);
      if (payment == null) {
        throw Exception('Payment not found');
      }

      if (payment.status != PaymentStatus.completed) {
        throw Exception('Only completed payments can be refunded');
      }

      // Call payment gateway API to process refund
      final response = await _apiService.post(
        '${APIEndpoints.payments}/refund',
        {'paymentId': paymentId},
      );

      final updatedPayment = PaymentDetails.fromJson(response);
      if (updatedPayment.status == PaymentStatus.refunded) {
        // Create refund transaction
        final refundTransaction = Transaction(
          id: '${paymentId}_refund',
          title: 'Refund: ${payment.description}',
          amount: payment.amount,
          timestamp: DateTime.now(),
          type: TransactionType.credit,
          category: TransactionCategory.others,
          upiId: '',
          description: 'Payment Refund',
          payeeId: '',
        );

        await _databaseService.addTransaction(refundTransaction);
        return true;
      }
      return false;
    } catch (e) {
      throw Exception('Failed to process refund: $e');
    }
  }

  Future<void> clearPaymentData() async {
    try {
      await _storage.delete(key: _pendingPaymentsKey);
    } catch (e) {
      throw Exception('Failed to clear payment data: $e');
    }
  }

  // Get payment history with optional filters
  Future<List<PaymentDetails>> getPaymentHistory({
    DateTime? startDate,
    DateTime? endDate,
    PaymentStatus? status,
    double? minAmount,
    double? maxAmount,
  }) async {
    try {
      final queryParams = <String, String>{
        if (startDate != null) 'startDate': startDate.toIso8601String(),
        if (endDate != null) 'endDate': endDate.toIso8601String(),
        if (status != null) 'status': status.toString().split('.').last,
        if (minAmount != null) 'minAmount': minAmount.toString(),
        if (maxAmount != null) 'maxAmount': maxAmount.toString(),
      };

      final response = await _apiService.get(
        '${APIEndpoints.payments}/history${_buildQueryString(queryParams)}',
      );

      final List<dynamic> paymentsJson = response['payments'];
      return paymentsJson.map((json) => PaymentDetails.fromJson(json)).toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    } catch (e) {
      throw Exception('Failed to get payment history: $e');
    }
  }

  // Process all pending payments that are ready
  Future<List<PaymentDetails>> processPendingPayments() async {
    try {
      final pendingPayments = await _loadPendingPayments();
      final results = <PaymentDetails>[];

      for (final payment in pendingPayments.values) {
        try {
          final processedPayment = await processPayment(payment.id);
          results.add(processedPayment);
        } catch (e) {
          // Log error but continue processing other payments
          print('Failed to process payment ${payment.id}: $e');
        }
      }

      return results;
    } catch (e) {
      throw Exception('Failed to process pending payments: $e');
    }
  }

  // Get payment analytics
  Future<Map<String, dynamic>> getPaymentAnalytics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final queryParams = <String, String>{
        if (startDate != null) 'startDate': startDate.toIso8601String(),
        if (endDate != null) 'endDate': endDate.toIso8601String(),
      };

      final response = await _apiService.get(
        '${APIEndpoints.payments}/analytics${_buildQueryString(queryParams)}',
      );

      return {
        'totalAmount': response['totalAmount'] as double,
        'successfulPayments': response['successfulPayments'] as int,
        'failedPayments': response['failedPayments'] as int,
        'averageAmount': response['averageAmount'] as double,
        'topCategories': List<String>.from(response['topCategories']),
        'paymentsByStatus': Map<String, int>.from(response['paymentsByStatus']),
        'dailyTotals': Map<String, double>.from(response['dailyTotals']),
      };
    } catch (e) {
      throw Exception('Failed to get payment analytics: $e');
    }
  }

  // Update payment status from server
  Future<PaymentDetails> updatePaymentStatus(String paymentId) async {
    try {
      final response = await _apiService.get(
        '${APIEndpoints.payments}/status/$paymentId',
      );

      final updatedPayment = PaymentDetails.fromJson(response);

      // If payment is no longer pending, remove from pending payments
      if (updatedPayment.status != PaymentStatus.pending &&
          updatedPayment.status != PaymentStatus.processing) {
        await _removePendingPayment(paymentId);

        // Create transaction for completed payments
        if (updatedPayment.status == PaymentStatus.completed) {
          await _createTransaction(updatedPayment);
        }
        // Create refund transaction for refunded payments
        else if (updatedPayment.status == PaymentStatus.refunded) {
          final refundTransaction = Transaction(
            id: '${paymentId}_refund',
            title: 'Refund: ${updatedPayment.description}',
            amount: updatedPayment.amount,
            timestamp: DateTime.now(),
            type: TransactionType.credit,
            category: TransactionCategory.others,
            upiId: '',
            description: 'Payment Refund',
            payeeId: '',
          );
          await _databaseService.addTransaction(refundTransaction);
        }
      }

      return updatedPayment;
    } catch (e) {
      // If server is unavailable, return local status
      final localPayment = await getPaymentStatus(paymentId);
      if (localPayment == null) {
        throw Exception('Payment not found');
      }
      return localPayment;
    }
  }

  // Get payment statistics by category
  Future<Map<TransactionCategory, Map<String, dynamic>>>
      getPaymentStatsByCategory({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final queryParams = <String, String>{
        if (startDate != null) 'startDate': startDate.toIso8601String(),
        if (endDate != null) 'endDate': endDate.toIso8601String(),
      };

      final response = await _apiService.get(
        '${APIEndpoints.payments}/category-stats${_buildQueryString(queryParams)}',
      );

      return Map.fromEntries(
        (response['categoryStats'] as Map<String, dynamic>)
            .entries
            .map((entry) {
          final category = TransactionCategory.values.firstWhere(
            (c) => c.toString().split('.').last == entry.key,
            orElse: () => TransactionCategory.others,
          );
          return MapEntry(category, Map<String, dynamic>.from(entry.value));
        }),
      );
    } catch (e) {
      throw Exception('Failed to get category statistics: $e');
    }
  }

  String _buildQueryString(Map<String, String> params) {
    if (params.isEmpty) return '';
    return '?' +
        params.entries
            .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
            .join('&');
  }

  Future<bool> handleUPICallback(Map<String, dynamic> callbackData) async {
    try {
      final paymentId = callbackData['paymentId'];
      final txnId = callbackData['txnId'];
      final status = callbackData['status'];

      final payment = await getPaymentStatus(paymentId);
      if (payment == null) {
        throw Exception('Payment not found');
      }

      final response = await _apiService.post(
        '${APIEndpoints.payments}/upi-callback',
        {
          'paymentId': paymentId,
          'txnId': txnId,
          'status': status,
          'rawResponse': callbackData,
        },
      );

      final updatedPayment = PaymentDetails.fromJson(response);
      if (updatedPayment.status == PaymentStatus.completed) {
        await _createTransaction(updatedPayment);
        await _removePendingPayment(paymentId);
        return true;
      }
      return false;
    } catch (e) {
      throw Exception('Failed to handle UPI callback: $e');
    }
  }

  Future<String> generateUPIDeepLink({
    required String paymentId,
    required UPIProvider provider,
    required String upiId,
  }) async {
    try {
      final payment = await getPaymentStatus(paymentId);
      if (payment == null) {
        throw Exception('Payment not found');
      }

      final response = await _apiService.post(
        '${APIEndpoints.payments}/upi-deep-link',
        {
          'paymentId': paymentId,
          'provider': provider.toString().split('.').last,
          'upiId': upiId,
        },
      );

      return response['deepLink'];
    } catch (e) {
      throw Exception('Failed to generate UPI deep link: $e');
    }
  }

  Future<PaymentResult> processAddMoney({
    required double amount,
    required String method,
  }) async {
    try {
      final walletService = WalletService();
      PaymentGateway gateway;
      UPIProvider? upiProvider;

      // Determine gateway based on method
      switch (method) {
        case 'UPI':
          gateway = PaymentGateway.upi;
          upiProvider = UPIProvider.googlePay; // Default to Google Pay
          break;
        case 'Bank Transfer':
          gateway = PaymentGateway.razorpay;
          break;
        case 'Credit/Debit Card':
          gateway = PaymentGateway.stripe;
          break;
        default:
          gateway = PaymentGateway.upi;
      }

      // Call backend API to initiate wallet topup
      final response = await walletService.addMoneyToWallet(
        amount: amount,
        method: method,
        gateway: gateway.toString().split('.').last,
        upiProvider: upiProvider?.toString().split('.').last,
      );

      final String paymentId = response['paymentId'];

      // Initiate payment with the payment gateway
      final payment = await initiatePayment(
        amount: amount,
        currency: 'INR',
        description: 'Add money to wallet',
        preferredGateway: gateway,
        upiProvider: upiProvider,
        metadata: {
          'type': 'wallet_topup',
          'method': method,
          'walletTopupId': paymentId,
        },
      );

      // Process the payment
      final processedPayment = await processPayment(payment.id);

      // Update wallet balance on the backend
      if (processedPayment.status == PaymentStatus.completed) {
        await walletService.confirmWalletTopup(
          paymentId: paymentId,
          gatewayPaymentId: processedPayment.id,
          status: processedPayment.status.toString().split('.').last,
        );

        return PaymentResult(
          success: true,
          message: 'Successfully added ₹$amount to your wallet',
          details: processedPayment,
        );
      } else if (processedPayment.status == PaymentStatus.processing) {
        return PaymentResult(
          success: true,
          message:
              'Your payment is being processed. Money will be added to your wallet shortly.',
          details: processedPayment,
        );
      } else {
        // Update failed status on backend
        await walletService.confirmWalletTopup(
          paymentId: paymentId,
          gatewayPaymentId: processedPayment.id,
          status: processedPayment.status.toString().split('.').last,
        );

        return PaymentResult(
          success: false,
          message:
              'Payment ${processedPayment.status.toString().split('.').last}. Please try again.',
          details: processedPayment,
        );
      }
    } catch (e) {
      return PaymentResult(
        success: false,
        message: 'Failed to process payment: ${e.toString()}',
      );
    }
  }

  Future<PaymentResult> sendMoney({
    required String recipientId,
    required double amount,
    String? note,
  }) async {
    try {
      final walletService = WalletService();

      // Check if user has sufficient balance
      final balance = await walletService.getWalletBalance();
      if (balance < amount) {
        return PaymentResult(
          success: false,
          message: 'Insufficient balance in your wallet',
        );
      }

      // Call backend API to initiate money transfer
      final response = await _apiService.post(
        '${APIEndpoints.payments}/transfer',
        {
          'recipientId': recipientId,
          'amount': amount,
          'note': note ?? 'Money transfer',
        },
      );

      final String transactionId = response['transactionId'];
      final String status = response['status'];

      if (status == 'completed' || status == 'processing') {
        // Create transaction record
        final transaction = Transaction(
          id: transactionId,
          title: 'Money sent',
          amount: amount,
          timestamp: DateTime.now(),
          type: TransactionType.debit,
          category: TransactionCategory.others,
          payeeId: recipientId,
          description: note ?? 'Money transfer',
        );

        await _databaseService.addTransaction(transaction);

        return PaymentResult(
          success: true,
          message: status == 'completed'
              ? 'Successfully sent ₹$amount'
              : 'Transfer is being processed',
          details: PaymentDetails(
            id: transactionId,
            amount: amount,
            currency: 'INR',
            description: note ?? 'Money transfer',
            status: status == 'completed'
                ? PaymentStatus.completed
                : PaymentStatus.processing,
            timestamp: DateTime.now(),
            metadata: {
              'recipientId': recipientId,
              'type': 'money_transfer',
            },
          ),
        );
      } else {
        return PaymentResult(
          success: false,
          message: 'Transfer failed: ${response['message'] ?? 'Unknown error'}',
        );
      }
    } catch (e) {
      return PaymentResult(
        success: false,
        message: 'Failed to send money: ${e.toString()}',
      );
    }
  }

  Future<PaymentResult> transferToBank({
    required String bankName,
    required String accountNumber,
    required String ifscCode,
    required String accountHolderName,
    required double amount,
    String? note,
  }) async {
    try {
      final walletService = WalletService();

      // Check if user has sufficient balance
      final balance = await walletService.getWalletBalance();
      if (balance < amount) {
        return PaymentResult(
          success: false,
          message: 'Insufficient balance in your wallet',
        );
      }

      // Call backend API to initiate bank transfer
      final response = await _apiService.post(
        '${APIEndpoints.payments}/bank-transfer',
        {
          'bankName': bankName,
          'accountNumber': accountNumber,
          'ifscCode': ifscCode,
          'accountHolderName': accountHolderName,
          'amount': amount,
          'note': note ?? 'Bank transfer',
        },
      );

      final String transactionId = response['transactionId'];
      final String status = response['status'];

      if (status == 'initiated' || status == 'processing') {
        // Create transaction record
        final transaction = Transaction(
          id: transactionId,
          title: 'Bank Transfer',
          amount: amount,
          timestamp: DateTime.now(),
          type: TransactionType.debit,
          category: TransactionCategory.others,
          description: note ?? 'Bank transfer to $accountHolderName',
        );

        await _databaseService.addTransaction(transaction);

        return PaymentResult(
          success: true,
          message: 'Transfer initiated successfully',
          details: PaymentDetails(
            id: transactionId,
            amount: amount,
            currency: 'INR',
            description: note ?? 'Bank transfer to $accountHolderName',
            status: status == 'initiated'
                ? PaymentStatus.pending
                : PaymentStatus.processing,
            timestamp: DateTime.now(),
            metadata: {
              'bankName': bankName,
              'accountNumber': accountNumber,
              'ifscCode': ifscCode,
              'accountHolderName': accountHolderName,
              'type': 'bank_transfer',
            },
          ),
        );
      } else {
        return PaymentResult(
          success: false,
          message: 'Transfer failed: ${response['message'] ?? 'Unknown error'}',
        );
      }
    } catch (e) {
      return PaymentResult(
        success: false,
        message: 'Failed to process bank transfer: ${e.toString()}',
      );
    }
  }
}
