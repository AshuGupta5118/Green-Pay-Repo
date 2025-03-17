import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:green_pay/models/contact.dart';
import 'package:green_pay/models/transaction.dart';
import 'package:green_pay/services/contact_service.dart';
import 'package:green_pay/services/payment_service.dart';
import 'package:green_pay/services/wallet_service.dart';
import 'package:green_pay/services/api_service.dart';
import 'package:uuid/uuid.dart';

class SendMoneyScreen extends StatefulWidget {
  const SendMoneyScreen({Key? key}) : super(key: key);

  @override
  State<SendMoneyScreen> createState() => _SendMoneyScreenState();
}

class _SendMoneyScreenState extends State<SendMoneyScreen>
    with SingleTickerProviderStateMixin {
  final _apiService = APIService();
  late final ContactService _contactService = ContactService(
    ApiService(baseUrl: APIEndpoints.baseUrl),
  );
  final PaymentService _paymentService = PaymentService();
  final WalletService _walletService = WalletService();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  List<Contact> _contacts = [];
  List<Contact> _filteredContacts = [];
  bool _isLoading = true;
  bool _isProcessing = false;
  String? _errorMessage;

  final TextEditingController _searchController = TextEditingController();
  Contact? _selectedContact;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  double _walletBalance = 0.0;

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

    _loadContacts();
    _loadWalletBalance();
    _animationController.forward();

    _searchController.addListener(_filterContacts);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadContacts() async {
    try {
      final contacts = await _contactService.getContacts();
      setState(() {
        _contacts = contacts;
        _filteredContacts = contacts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load contacts: ${e.toString()}';
        _isLoading = false;
      });
    }
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

  void _filterContacts() {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) {
      setState(() {
        _filteredContacts = _contacts;
      });
      return;
    }

    setState(() {
      _filteredContacts = _contacts.where((contact) {
        return contact.name.toLowerCase().contains(query) ||
            (contact.phoneNumber?.toLowerCase().contains(query) ?? false) ||
            (contact.email?.toLowerCase().contains(query) ?? false);
      }).toList();
    });
  }

  void _selectContact(Contact contact) {
    setState(() {
      _selectedContact = contact;
    });

    // Show amount input dialog
    _showAmountInputDialog();
  }

  void _showAmountInputDialog() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => _buildAmountInputDialog(),
    );
  }

  Widget _buildAmountInputDialog() {
    return CupertinoActionSheet(
      title: Text('Send money to ${_selectedContact?.name}'),
      message: Column(
        children: [
          const SizedBox(height: 16),
          CupertinoTextField(
            controller: _amountController,
            placeholder: 'Enter amount',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            prefix: const Padding(
              padding: EdgeInsets.only(left: 12.0),
              child: Text('₹', style: TextStyle(fontSize: 20)),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: CupertinoColors.systemGrey4),
              borderRadius: BorderRadius.circular(8),
            ),
            style: const TextStyle(fontSize: 20),
          ),
          const SizedBox(height: 16),
          CupertinoTextField(
            controller: _noteController,
            placeholder: 'Add a note (optional)',
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: CupertinoColors.systemGrey4),
              borderRadius: BorderRadius.circular(8),
            ),
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
        ],
      ),
      actions: [
        CupertinoActionSheetAction(
          onPressed: _processSendMoney,
          child: _isProcessing
              ? const CupertinoActivityIndicator()
              : const Text('Send Money'),
        ),
      ],
      cancelButton: CupertinoActionSheetAction(
        onPressed: () {
          Navigator.pop(context);
          _amountController.clear();
          _noteController.clear();
          _errorMessage = null;
        },
        child: const Text('Cancel'),
      ),
    );
  }

  Future<void> _processSendMoney() async {
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
      // Process payment
      final result = await _paymentService.sendMoney(
        recipientId: _selectedContact!.id,
        amount: amount,
        note: _noteController.text,
      );

      // Close the dialog
      Navigator.pop(context);

      if (result.success) {
        // Show success dialog
        _showSuccessDialog(amount);
      } else {
        _showErrorDialog(result.message ?? 'Failed to send money');
      }
    } catch (e) {
      Navigator.pop(context);
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
        title: const Text('Money Sent'),
        content: Text('₹$amount has been sent to ${_selectedContact?.name}'),
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

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Send Money'),
        border: null,
      ),
      child: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: CupertinoSearchTextField(
                    controller: _searchController,
                    placeholder: 'Search contacts',
                    onChanged: (value) => _filterContacts(),
                  ),
                ),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CupertinoActivityIndicator())
                      : _filteredContacts.isEmpty
                          ? _buildEmptyState()
                          : _buildContactsList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            CupertinoIcons.person_2_fill,
            size: 48,
            color: CupertinoColors.systemGrey,
          ),
          const SizedBox(height: 16),
          Text(
            _searchController.text.isNotEmpty
                ? 'No contacts found'
                : 'No contacts available',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchController.text.isNotEmpty
                ? 'Try a different search term'
                : 'Add contacts to send money',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: CupertinoColors.systemGrey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactsList() {
    return CupertinoScrollbar(
      child: ListView.separated(
        itemCount: _filteredContacts.length,
        separatorBuilder: (context, index) => const Divider(
          height: 1,
          indent: 70,
        ),
        itemBuilder: (context, index) {
          final contact = _filteredContacts[index];
          return _buildContactItem(contact);
        },
      ),
    );
  }

  Widget _buildContactItem(Contact contact) {
    return CupertinoListTile(
      leading: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: CupertinoColors.systemBlue.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            contact.name.isNotEmpty ? contact.name[0].toUpperCase() : '?',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: CupertinoTheme.of(context).primaryColor,
            ),
          ),
        ),
      ),
      title: Text(
        contact.name,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        contact.phoneNumber ?? 'No phone number',
        style: const TextStyle(
          fontSize: 14,
          color: CupertinoColors.systemGrey,
        ),
      ),
      trailing: const Icon(CupertinoIcons.chevron_right),
      onTap: () => _selectContact(contact),
    );
  }
}
