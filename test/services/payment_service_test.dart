import 'package:flutter_test/flutter_test.dart';
import 'package:green_pay/services/payment_service.dart';

void main() {
  late PaymentService paymentService;

  setUp(() {
    paymentService = PaymentService();
  });

  group('PaymentService', () {
    test('initiatePayment creates payment with correct details', () async {
      final payment = await paymentService.initiatePayment(
        amount: 100.0,
        currency: 'INR',
        description: 'Test payment',
        preferredGateway: PaymentGateway.upi,
        upiProvider: UPIProvider.googlePay,
      );

      expect(payment.amount, equals(100.0));
      expect(payment.currency, equals('INR'));
      expect(payment.description, equals('Test payment'));
      expect(payment.status, equals(PaymentStatus.pending));
      expect(payment.gateway, equals(PaymentGateway.upi));
      expect(payment.upiProvider, equals(UPIProvider.googlePay));
    });

    test('processPayment handles successful payment', () async {
      // First create a payment
      final payment = await paymentService.initiatePayment(
        amount: 100.0,
        currency: 'INR',
        description: 'Test payment',
        preferredGateway: PaymentGateway.upi,
        upiProvider: UPIProvider.googlePay,
      );

      // Then process it
      final processedPayment = await paymentService.processPayment(payment.id);
      expect(processedPayment.status, equals(PaymentStatus.completed));
    });

    test('handleUPICallback processes successful UPI payment', () async {
      // First create a payment
      final payment = await paymentService.initiatePayment(
        amount: 100.0,
        currency: 'INR',
        description: 'Test payment',
        preferredGateway: PaymentGateway.upi,
        upiProvider: UPIProvider.googlePay,
      );

      final callbackData = {
        'paymentId': payment.id,
        'txnId': 'test_txn_id',
        'status': 'SUCCESS',
      };

      final result = await paymentService.handleUPICallback(callbackData);
      expect(result, isTrue);
    });

    test('generateUPIDeepLink creates correct deep link', () async {
      // First create a payment
      final payment = await paymentService.initiatePayment(
        amount: 100.0,
        currency: 'INR',
        description: 'Test payment',
        preferredGateway: PaymentGateway.upi,
        upiProvider: UPIProvider.googlePay,
      );

      final deepLink = await paymentService.generateUPIDeepLink(
        paymentId: payment.id,
        provider: UPIProvider.googlePay,
        upiId: 'merchant@upi',
      );

      expect(deepLink, startsWith('upi://pay'));
      expect(deepLink, contains('pa=merchant@upi'));
    });
  });
}
