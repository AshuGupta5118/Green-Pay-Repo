import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'ui_components.dart';

class PaymentProcessingOverlay extends StatelessWidget {
  final String message;
  final bool showConfetti;

  const PaymentProcessingOverlay({
    Key? key,
    required this.message,
    this.showConfetti = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withOpacity(0.8),
      child: Stack(
        children: [
          if (showConfetti)
            Positioned.fill(
              child: Lottie.asset(
                'assets/animations/confetti.json',
                repeat: true,
              ),
            ),
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 100,
                    width: 100,
                    child: showConfetti
                        ? Lottie.asset(
                            'assets/animations/success.json',
                            repeat: false,
                          )
                        : Lottie.asset(
                            'assets/animations/loading.json',
                            repeat: true,
                          ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    message,
                    style: GreenPayUI.bodyStyle.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PaymentResult {
  final bool success;
  final String message;
  final String? transactionId;
  final double? amount;

  const PaymentResult({
    required this.success,
    required this.message,
    this.transactionId,
    this.amount,
  });
}

Future<void> showPaymentProcessing({
  required BuildContext context,
  required Future<PaymentResult> Function() processPayment,
  String processingMessage = 'Processing your payment...',
  String successMessage = 'Payment successful!',
  String errorMessage = 'Payment failed.',
  VoidCallback? onSuccess,
  VoidCallback? onError,
}) async {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => PaymentProcessingOverlay(
      message: processingMessage,
    ),
  );

  try {
    final result = await processPayment();
    Navigator.of(context).pop(); // Remove processing overlay

    if (result.success) {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => PaymentProcessingOverlay(
          message: successMessage,
          showConfetti: true,
        ),
      );

      await Future.delayed(const Duration(seconds: 2));
      if (context.mounted) {
        Navigator.of(context).pop(); // Remove success overlay
        onSuccess?.call();
      }
    } else {
      await GreenPayUI.showErrorDialog(
        context: context,
        title: 'Payment Failed',
        message: result.message,
      );
      onError?.call();
    }
  } catch (e) {
    if (context.mounted) {
      Navigator.of(context).pop(); // Remove processing overlay
      await GreenPayUI.showErrorDialog(
        context: context,
        title: 'Error',
        message: errorMessage,
      );
      onError?.call();
    }
  }
} 