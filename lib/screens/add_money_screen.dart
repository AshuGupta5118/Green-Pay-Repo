import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:green_pay/services/payment_service.dart';
import 'package:green_pay/services/database_service.dart';
import 'package:green_pay/models/transaction.dart';
import 'package:uuid/uuid.dart';
import 'package:url_launcher/url_launcher.dart';

class AddMoneyScreen extends StatefulWidget {
  const AddMoneyScreen({Key? key}) : super(key: key);

  @override
  State<AddMoneyScreen> createState() => _AddMoneyScreenState();
}

class _AddMoneyScreenState extends State<AddMoneyScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _amountController = TextEditingController();
  final PaymentService _paymentService = PaymentService();
  final DatabaseService _databaseService = DatabaseService();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  String _selectedMethod = 'UPI';
  bool _isProcessing = false;
  String? _errorMessage;
  PaymentDetails? _currentPayment;
  StreamSubscription<PaymentDetails>? _paymentSubscription;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );

    _animationController.forward();

    // Initialize payment service
    _paymentService.initialize();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _animationController.dispose();
    _paymentSubscription?.cancel();
    super.dispose();
  }

  Future<void> _processAddMoney() async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      setState(() {
        _errorMessage = 'Please enter a valid amount';
      });
      return;
    }

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      // Process payment based on selected method
      final paymentResult = await _paymentService.processAddMoney(
        amount: amount,
        method: _selectedMethod,
      );

      if (paymentResult.success) {
        _currentPayment = paymentResult.details;

        if (_currentPayment != null) {
          // Listen for payment status updates
          _listenForPaymentUpdates(_currentPayment!.id);

          // Handle different payment methods
          if (_selectedMethod == 'UPI' &&
              _currentPayment!.gateway == PaymentGateway.upi) {
            await _handleUPIPayment(_currentPayment!);
          } else if (_selectedMethod == 'Credit/Debit Card' &&
              _currentPayment!.gateway == PaymentGateway.stripe) {
            await _handleCardPayment(_currentPayment!);
          } else if (_selectedMethod == 'Bank Transfer' &&
              _currentPayment!.gateway == PaymentGateway.razorpay) {
            await _handleBankTransfer(_currentPayment!);
          } else {
            // Create a transaction record
            await _createTransactionRecord(amount);

            if (mounted) {
              Navigator.pop(context, true); // Return success
            }
          }
        } else {
          // Create a transaction record
          await _createTransactionRecord(amount);

          if (mounted) {
            Navigator.pop(context, true); // Return success
          }
        }
      } else {
        setState(() {
          _isProcessing = false;
          _errorMessage = paymentResult.message ?? 'Payment failed';
        });
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _errorMessage = 'An error occurred: ${e.toString()}';
      });
    }
  }

  Future<void> _createTransactionRecord(double amount) async {
    // Create a transaction record
    final transaction = Transaction(
      id: const Uuid().v4(),
      title: 'Added Money via $_selectedMethod',
      amount: amount,
      timestamp: DateTime.now(),
      type: TransactionType.credit,
      category: TransactionCategory.others,
      description: 'Money added to wallet',
    );

    await _databaseService.addTransaction(transaction);
  }

  void _listenForPaymentUpdates(String paymentId) {
    _paymentSubscription =
        _paymentService.getPaymentUpdates(paymentId).listen((payment) {
      if (payment.status == PaymentStatus.completed) {
        if (mounted) {
          Navigator.pop(context, true); // Return success
        }
      } else if (payment.status == PaymentStatus.failed ||
          payment.status == PaymentStatus.cancelled) {
        setState(() {
          _isProcessing = false;
          _errorMessage =
              'Payment ${payment.status.toString().split('.').last}. Please try again.';
        });
      }
    }, onError: (error) {
      setState(() {
        _isProcessing = false;
        _errorMessage = 'Error tracking payment: $error';
      });
    });
  }

  Future<void> _handleUPIPayment(PaymentDetails payment) async {
    // Generate UPI deep link
    final upiProvider = payment.upiProvider ?? UPIProvider.googlePay;
    final deepLink = await _paymentService.generateUPIDeepLink(
      paymentId: payment.id,
      provider: upiProvider,
      upiId: 'merchant@upi', // This should come from your backend
    );

    // Launch UPI app
    if (await canLaunchUrl(Uri.parse(deepLink))) {
      await launchUrl(Uri.parse(deepLink),
          mode: LaunchMode.externalApplication);
    } else {
      setState(() {
        _isProcessing = false;
        _errorMessage = 'Could not launch UPI app';
      });
    }
  }

  Future<void> _handleCardPayment(PaymentDetails payment) async {
    // Show card payment form
    showCupertinoModalPopup(
      context: context,
      builder: (context) => _buildCardPaymentForm(payment),
    );
  }

  Future<void> _handleBankTransfer(PaymentDetails payment) async {
    // Show bank transfer instructions
    showCupertinoModalPopup(
      context: context,
      builder: (context) => _buildBankTransferInstructions(payment),
    );
  }

  Widget _buildCardPaymentForm(PaymentDetails payment) {
    return CupertinoActionSheet(
      title: const Text('Enter Card Details'),
      message: const Text('Your payment is being processed securely'),
      actions: [
        CupertinoActionSheetAction(
          onPressed: () {
            Navigator.pop(context);
            // Simulate successful payment
            _paymentService.updatePaymentStatus(payment.id);
          },
          child: const Text('Complete Payment'),
        ),
      ],
      cancelButton: CupertinoActionSheetAction(
        onPressed: () {
          Navigator.pop(context);
          setState(() {
            _isProcessing = false;
          });
        },
        child: const Text('Cancel'),
      ),
    );
  }

  Widget _buildBankTransferInstructions(PaymentDetails payment) {
    return CupertinoActionSheet(
      title: const Text('Bank Transfer Instructions'),
      message: Column(
        children: [
          const Text('Transfer the amount to the following account:'),
          const SizedBox(height: 16),
          const Text('Account Name: Green Pay Pvt Ltd'),
          const Text('Account Number: 1234567890'),
          const Text('IFSC Code: ABCD0001234'),
          const SizedBox(height: 16),
          Text('Reference: ${payment.id}'),
          const SizedBox(height: 16),
          const Text(
              'Your wallet will be updated once the transfer is confirmed.'),
        ],
      ),
      actions: [
        CupertinoActionSheetAction(
          onPressed: () {
            Navigator.pop(context);
            // Simulate successful payment
            _paymentService.updatePaymentStatus(payment.id);
          },
          child: const Text('I have completed the transfer'),
        ),
      ],
      cancelButton: CupertinoActionSheetAction(
        onPressed: () {
          Navigator.pop(context);
          setState(() {
            _isProcessing = false;
          });
        },
        child: const Text('Cancel'),
      ),
    );
  }

  Widget _buildPaymentMethodOption(String method, IconData icon) {
    final isSelected = _selectedMethod == method;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMethod = method;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? CupertinoColors.activeBlue.withOpacity(0.1)
              : CupertinoColors.systemBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? CupertinoColors.activeBlue
                : CupertinoColors.systemGrey4,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? CupertinoColors.activeBlue
                  : CupertinoColors.systemGrey,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              method,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected
                    ? CupertinoColors.activeBlue
                    : CupertinoColors.label,
              ),
            ),
            const Spacer(),
            if (isSelected)
              const Icon(
                CupertinoIcons.checkmark_circle_fill,
                color: CupertinoColors.activeBlue,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Add Money'),
        border: null,
      ),
      child: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Amount input
                  CupertinoTextField(
                    controller: _amountController,
                    placeholder: 'Enter amount',
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    prefix: const Padding(
                      padding: EdgeInsets.only(left: 12.0),
                      child: Text('₹', style: TextStyle(fontSize: 20)),
                    ),
                    padding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: CupertinoColors.systemGrey4),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    style: const TextStyle(fontSize: 20),
                  ),
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: CupertinoColors.destructiveRed,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),

                  // Payment method selection
                  const Text(
                    'Select Payment Method',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),

                  _buildPaymentMethodOption(
                      'UPI', CupertinoIcons.money_dollar_circle),
                  const SizedBox(height: 12),
                  _buildPaymentMethodOption(
                      'Bank Transfer', CupertinoIcons.building_2_fill),
                  const SizedBox(height: 12),
                  _buildPaymentMethodOption(
                      'Credit/Debit Card', CupertinoIcons.creditcard),

                  const Spacer(),

                  // Process button
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    color: CupertinoColors.activeGreen,
                    onPressed: _isProcessing ? null : _processAddMoney,
                    child: _isProcessing
                        ? const CupertinoActivityIndicator(
                            color: CupertinoColors.white)
                        : const Text(
                            'Add Money',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
