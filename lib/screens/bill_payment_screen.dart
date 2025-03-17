import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:green_pay/models/bill.dart';
import 'package:green_pay/models/bill_provider.dart';
import 'package:green_pay/services/bills_service.dart';
import 'package:green_pay/screens/bill_receipt_screen.dart';

class BillPaymentScreen extends StatefulWidget {
  final String category;
  final BillProvider provider;
  final double walletBalance;

  const BillPaymentScreen({
    Key? key,
    required this.category,
    required this.provider,
    required this.walletBalance,
  }) : super(key: key);

  @override
  State<BillPaymentScreen> createState() => _BillPaymentScreenState();
}

class _BillPaymentScreenState extends State<BillPaymentScreen>
    with SingleTickerProviderStateMixin {
  final BillsService _billsService = BillsService();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final TextEditingController _customerNumberController =
      TextEditingController();
  final TextEditingController _consumerNumberController =
      TextEditingController();
  final TextEditingController _mobileNumberController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  bool _isLoading = false;
  bool _isFetchingBill = false;
  bool _isPayingBill = false;
  String? _errorMessage;
  Bill? _bill;
  int _currentStep = 0;

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
  }

  @override
  void dispose() {
    _animationController.dispose();
    _customerNumberController.dispose();
    _consumerNumberController.dispose();
    _mobileNumberController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _fetchBillDetails() async {
    // Validate inputs
    if (_customerNumberController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter customer number';
      });
      return;
    }

    if (widget.provider.requiresConsumerNumber &&
        _consumerNumberController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter consumer number';
      });
      return;
    }

    setState(() {
      _isFetchingBill = true;
      _errorMessage = null;
    });

    try {
      final bill = await _billsService.fetchBillDetails(
        providerId: widget.provider.id,
        customerNumber: _customerNumberController.text,
        consumerNumber: widget.provider.requiresConsumerNumber
            ? _consumerNumberController.text
            : null,
      );

      setState(() {
        _bill = bill;
        _isFetchingBill = false;
        _currentStep = 1;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isFetchingBill = false;
      });
    }
  }

  Future<void> _payBill() async {
    // Validate inputs
    if (_mobileNumberController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter mobile number';
      });
      return;
    }

    if (widget.provider.requiresEmailId && _emailController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter email ID';
      });
      return;
    }

    if (_bill == null) {
      setState(() {
        _errorMessage = 'Bill details not available';
      });
      return;
    }

    if (_bill!.amount > widget.walletBalance) {
      setState(() {
        _errorMessage = 'Insufficient wallet balance';
      });
      return;
    }

    setState(() {
      _isPayingBill = true;
      _errorMessage = null;
    });

    try {
      final paidBill = await _billsService.payBill(
        billId: _bill!.id,
        amount: _bill!.amount,
        mobileNumber: _mobileNumberController.text,
        emailId: widget.provider.requiresEmailId ? _emailController.text : null,
      );

      // Navigate to receipt screen
      if (mounted) {
        Navigator.pushReplacement(
          context,
          CupertinoPageRoute(
            builder: (context) => BillReceiptScreen(bill: paidBill),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isPayingBill = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('Pay ${widget.provider.name} Bill'),
        border: null,
      ),
      child: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: _isLoading
                ? const Center(child: CupertinoActivityIndicator())
                : _currentStep == 0
                    ? _buildCustomerDetailsForm()
                    : _buildBillPaymentForm(),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomerDetailsForm() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProviderHeader(),
                const SizedBox(height: 24),
                const Text(
                  'Enter Customer Details',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildInputField(
                  label: 'Customer Number',
                  placeholder: 'Enter customer number',
                  controller: _customerNumberController,
                  keyboardType: TextInputType.number,
                ),
                if (widget.provider.requiresConsumerNumber) ...[
                  const SizedBox(height: 16),
                  _buildInputField(
                    label: 'Consumer Number',
                    placeholder: 'Enter consumer number',
                    controller: _consumerNumberController,
                    keyboardType: TextInputType.number,
                  ),
                ],
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    style: const TextStyle(
                      color: CupertinoColors.systemRed,
                      fontSize: 14,
                    ),
                  ),
                ],
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
              onPressed: _isFetchingBill ? null : _fetchBillDetails,
              child: _isFetchingBill
                  ? const CupertinoActivityIndicator(
                      color: CupertinoColors.white)
                  : const Text('Fetch Bill'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBillPaymentForm() {
    if (_bill == null) {
      return const Center(child: Text('Bill details not available'));
    }

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProviderHeader(),
                const SizedBox(height: 24),
                _buildBillDetails(),
                const SizedBox(height: 24),
                const Text(
                  'Contact Details',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildInputField(
                  label: 'Mobile Number',
                  placeholder: 'Enter mobile number',
                  controller: _mobileNumberController,
                  keyboardType: TextInputType.phone,
                ),
                if (widget.provider.requiresEmailId) ...[
                  const SizedBox(height: 16),
                  _buildInputField(
                    label: 'Email ID',
                    placeholder: 'Enter email ID',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                  ),
                ],
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    style: const TextStyle(
                      color: CupertinoColors.systemRed,
                      fontSize: 14,
                    ),
                  ),
                ],
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
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(
                    CupertinoIcons.info_circle,
                    color: CupertinoColors.systemGrey,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Available balance: ₹${widget.walletBalance.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: CupertinoColors.systemGrey,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: CupertinoButton.filled(
                  padding: const EdgeInsets.symmetric(vertical: 14.0),
                  onPressed: _isPayingBill ? null : _payBill,
                  child: _isPayingBill
                      ? const CupertinoActivityIndicator(
                          color: CupertinoColors.white)
                      : Text('Pay ₹${_bill!.amount.toStringAsFixed(2)}'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProviderHeader() {
    return Row(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: CupertinoColors.systemGrey6,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: widget.provider.logoUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      widget.provider.logoUrl!,
                      width: 48,
                      height: 48,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        CupertinoIcons.building_2_fill,
                        size: 30,
                        color: CupertinoColors.systemGrey,
                      ),
                    ),
                  )
                : const Icon(
                    CupertinoIcons.building_2_fill,
                    size: 30,
                    color: CupertinoColors.systemGrey,
                  ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.provider.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.category,
                style: const TextStyle(
                  fontSize: 14,
                  color: CupertinoColors.systemGrey,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBillDetails() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Bill Details',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildBillDetailRow('Customer Number', _bill!.customerNumber),
          if (_bill!.consumerNumber != null)
            _buildBillDetailRow('Consumer Number', _bill!.consumerNumber!),
          _buildBillDetailRow('Due Date', _formatDate(_bill!.dueDate)),
          _buildBillDetailRow('Amount', '₹${_bill!.amount.toStringAsFixed(2)}'),
          _buildBillDetailRow('Status', _bill!.status),
        ],
      ),
    );
  }

  Widget _buildBillDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: CupertinoColors.systemGrey,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required String placeholder,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        CupertinoTextField(
          controller: controller,
          placeholder: placeholder,
          keyboardType: keyboardType,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            border: Border.all(color: CupertinoColors.systemGrey4),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
