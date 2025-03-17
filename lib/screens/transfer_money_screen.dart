import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:green_pay/models/transaction.dart';
import 'package:green_pay/services/payment_service.dart';
import 'package:green_pay/services/wallet_service.dart';
import 'package:uuid/uuid.dart';

class TransferMoneyScreen extends StatefulWidget {
  const TransferMoneyScreen({Key? key}) : super(key: key);

  @override
  State<TransferMoneyScreen> createState() => _TransferMoneyScreenState();
}

class _TransferMoneyScreenState extends State<TransferMoneyScreen>
    with SingleTickerProviderStateMixin {
  final PaymentService _paymentService = PaymentService();
  final WalletService _walletService = WalletService();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isLoading = false;
  bool _isProcessing = false;
  String? _errorMessage;
  double _walletBalance = 0.0;

  final TextEditingController _accountNumberController =
      TextEditingController();
  final TextEditingController _ifscCodeController = TextEditingController();
  final TextEditingController _accountHolderNameController =
      TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  int _currentStep = 0;
  final List<String> _bankNames = [
    'State Bank of India',
    'HDFC Bank',
    'ICICI Bank',
    'Axis Bank',
    'Kotak Mahindra Bank',
    'Yes Bank',
    'Punjab National Bank',
    'Bank of Baroda',
    'Other'
  ];
  String? _selectedBank;

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

    _loadWalletBalance();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _accountNumberController.dispose();
    _ifscCodeController.dispose();
    _accountHolderNameController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadWalletBalance() async {
    try {
      final balance = await _walletService.getWalletBalance();
      setState(() {
        _walletBalance = balance;
      });
    } catch (e) {
      // Handle error silently
    }
  }

  void _nextStep() {
    if (_currentStep == 0) {
      // Validate bank details
      if (_selectedBank == null) {
        setState(() {
          _errorMessage = 'Please select a bank';
        });
        return;
      }
      if (_accountNumberController.text.isEmpty) {
        setState(() {
          _errorMessage = 'Please enter account number';
        });
        return;
      }
      if (_ifscCodeController.text.isEmpty) {
        setState(() {
          _errorMessage = 'Please enter IFSC code';
        });
        return;
      }
      if (_accountHolderNameController.text.isEmpty) {
        setState(() {
          _errorMessage = 'Please enter account holder name';
        });
        return;
      }
    } else if (_currentStep == 1) {
      // Validate amount
      final amount = double.tryParse(_amountController.text);
      if (amount == null || amount <= 0) {
        setState(() {
          _errorMessage = 'Please enter a valid amount';
        });
        return;
      }
      if (amount > _walletBalance) {
        setState(() {
          _errorMessage = 'Insufficient balance';
        });
        return;
      }
    }

    setState(() {
      _errorMessage = null;
      _currentStep++;
    });
  }

  void _previousStep() {
    setState(() {
      _currentStep--;
      _errorMessage = null;
    });
  }

  Future<void> _processTransfer() async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      setState(() {
        _errorMessage = 'Please enter a valid amount';
      });
      return;
    }

    if (amount > _walletBalance) {
      setState(() {
        _errorMessage = 'Insufficient balance';
      });
      return;
    }

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      // Process bank transfer
      final result = await _paymentService.transferToBank(
        bankName: _selectedBank!,
        accountNumber: _accountNumberController.text,
        ifscCode: _ifscCodeController.text,
        accountHolderName: _accountHolderNameController.text,
        amount: amount,
        note: _noteController.text,
      );

      if (result.success) {
        // Show success dialog
        _showSuccessDialog(amount);
      } else {
        _showErrorDialog(result.message ?? 'Failed to transfer money');
      }
    } catch (e) {
      _showErrorDialog('An error occurred: ${e.toString()}');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _showSuccessDialog(double amount) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Transfer Initiated'),
        content: Text(
            'Your transfer of ₹$amount to ${_accountHolderNameController.text} has been initiated. It may take 1-2 business days to complete.'),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context, true); // Return success to home screen
            },
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildBankSelectionStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 16.0, top: 16.0, bottom: 8.0),
          child: Text(
            'Select Bank',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16.0),
          decoration: BoxDecoration(
            border: Border.all(color: CupertinoColors.systemGrey4),
            borderRadius: BorderRadius.circular(8),
          ),
          child: CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            onPressed: _showBankPicker,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _selectedBank ?? 'Select a bank',
                  style: TextStyle(
                    color: _selectedBank == null
                        ? CupertinoColors.systemGrey
                        : CupertinoColors.black,
                  ),
                ),
                const Icon(
                  CupertinoIcons.chevron_down,
                  color: CupertinoColors.systemGrey,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Padding(
          padding: EdgeInsets.only(left: 16.0, bottom: 8.0),
          child: Text(
            'Account Number',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: CupertinoTextField(
            controller: _accountNumberController,
            placeholder: 'Enter account number',
            keyboardType: TextInputType.number,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              border: Border.all(color: CupertinoColors.systemGrey4),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Padding(
          padding: EdgeInsets.only(left: 16.0, bottom: 8.0),
          child: Text(
            'IFSC Code',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: CupertinoTextField(
            controller: _ifscCodeController,
            placeholder: 'Enter IFSC code',
            textCapitalization: TextCapitalization.characters,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              border: Border.all(color: CupertinoColors.systemGrey4),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Padding(
          padding: EdgeInsets.only(left: 16.0, bottom: 8.0),
          child: Text(
            'Account Holder Name',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: CupertinoTextField(
            controller: _accountHolderNameController,
            placeholder: 'Enter account holder name',
            textCapitalization: TextCapitalization.words,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              border: Border.all(color: CupertinoColors.systemGrey4),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }

  void _showBankPicker() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: 250,
        color: CupertinoColors.systemBackground,
        child: Column(
          children: [
            Container(
              height: 50,
              color: CupertinoColors.systemGrey5,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    child: const Text('Cancel'),
                    onPressed: () => Navigator.pop(context),
                  ),
                  CupertinoButton(
                    child: const Text('Done'),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: CupertinoPicker(
                itemExtent: 40,
                onSelectedItemChanged: (index) {
                  setState(() {
                    _selectedBank = _bankNames[index];
                  });
                },
                children: _bankNames
                    .map((bank) => Center(child: Text(bank)))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Transfer Details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Bank: $_selectedBank',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 4),
              Text(
                'Account: ${_accountNumberController.text}',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 4),
              Text(
                'IFSC: ${_ifscCodeController.text}',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 4),
              Text(
                'Name: ${_accountHolderNameController.text}',
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        const SizedBox(height: 16),
        const Padding(
          padding: EdgeInsets.only(left: 16.0, bottom: 8.0),
          child: Text(
            'Amount',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: CupertinoTextField(
            controller: _amountController,
            placeholder: 'Enter amount',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            prefix: const Padding(
              padding: EdgeInsets.only(left: 12.0),
              child: Text('₹', style: TextStyle(fontSize: 20)),
            ),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              border: Border.all(color: CupertinoColors.systemGrey4),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Padding(
          padding: EdgeInsets.only(left: 16.0, bottom: 8.0),
          child: Text(
            'Note (Optional)',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: CupertinoTextField(
            controller: _noteController,
            placeholder: 'Add a note',
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              border: Border.all(color: CupertinoColors.systemGrey4),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              const Icon(
                CupertinoIcons.info_circle,
                color: CupertinoColors.systemGrey,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Available balance: ₹${_walletBalance.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: CupertinoColors.systemGrey,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmationStep() {
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Confirm Transfer',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildConfirmationItem('Bank', _selectedBank!),
              _buildConfirmationItem(
                  'Account Number', _accountNumberController.text),
              _buildConfirmationItem('IFSC Code', _ifscCodeController.text),
              _buildConfirmationItem(
                  'Account Holder', _accountHolderNameController.text),
              _buildConfirmationItem('Amount', '₹${amount.toStringAsFixed(2)}'),
              if (_noteController.text.isNotEmpty)
                _buildConfirmationItem('Note', _noteController.text),
              const SizedBox(height: 16),
              const Text(
                'By confirming this transfer, you agree to our terms and conditions. Bank transfers typically take 1-2 business days to process.',
                style: TextStyle(
                  color: CupertinoColors.systemGrey,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmationItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                color: CupertinoColors.systemGrey,
                fontSize: 16,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Transfer Money'),
        border: null,
        leading: _currentStep > 0
            ? CupertinoButton(
                padding: EdgeInsets.zero,
                child: const Icon(CupertinoIcons.back),
                onPressed: _previousStep,
              )
            : null,
      ),
      child: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Column(
              children: [
                Expanded(
                  child: _isLoading
                      ? const Center(child: CupertinoActivityIndicator())
                      : SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (_currentStep == 0)
                                _buildBankSelectionStep()
                              else if (_currentStep == 1)
                                _buildAmountStep()
                              else
                                _buildConfirmationStep(),
                              if (_errorMessage != null)
                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Text(
                                    _errorMessage!,
                                    style: const TextStyle(
                                      color: CupertinoColors.destructiveRed,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                ),
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: CupertinoColors.systemGrey5,
                        width: 1.0,
                      ),
                    ),
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: CupertinoButton.filled(
                      padding: const EdgeInsets.symmetric(vertical: 14.0),
                      onPressed: _isProcessing
                          ? null
                          : _currentStep < 2
                              ? _nextStep
                              : _processTransfer,
                      child: _isProcessing
                          ? const CupertinoActivityIndicator(
                              color: CupertinoColors.white)
                          : Text(_currentStep < 2
                              ? 'Continue'
                              : 'Confirm Transfer'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
