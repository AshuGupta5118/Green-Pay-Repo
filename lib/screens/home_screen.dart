import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:green_pay/screens/cards_screen.dart';
import 'package:green_pay/screens/qr_scanner_screen.dart';
import 'package:green_pay/screens/profile_screen.dart';
import 'package:green_pay/screens/transactions_screen.dart';
import 'package:green_pay/screens/add_money_screen.dart';
import 'package:green_pay/screens/transfer_money_screen.dart';
import 'package:green_pay/screens/send_money_screen.dart';
import 'package:green_pay/services/upi_service.dart';
import 'package:green_pay/services/database_service.dart';
import 'package:green_pay/services/wallet_service.dart';
import 'package:green_pay/models/upi_details.dart';
import 'package:green_pay/models/transaction.dart';
import 'package:green_pay/widgets/add_upi_bottom_sheet.dart';
import 'package:green_pay/theme/app_theme.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  final UPIService _upiService = UPIService();
  final DatabaseService _databaseService = DatabaseService();
  final WalletService _walletService = WalletService();
  List<UPIDetails> _upiAccounts = [];
  List<Transaction> _recentTransactions = [];
  bool _isLoadingUPI = true;
  bool _isLoadingTransactions = true;
  double _balance = 0.0;

  // Animation controllers
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _loadUPIAccounts();
    _loadTransactions();
    _loadBalance();

    // Initialize animations
    _animationController = AnimationController(
      duration: AppTheme.mediumAnimation,
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.1),
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
    super.dispose();
  }

  Future<void> _loadUPIAccounts() async {
    try {
      final accounts = await _upiService.getUPIAccounts();
      if (mounted) {
        setState(() {
          _upiAccounts = accounts;
          _isLoadingUPI = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingUPI = false;
        });
      }
    }
  }

  Future<void> _loadTransactions() async {
    try {
      final transactions = await _databaseService.getTransactions();
      setState(() {
        _recentTransactions = transactions.take(10).toList();
        _isLoadingTransactions = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingTransactions = false;
      });
    }
  }

  Future<void> _loadBalance() async {
    try {
      final balance = await _walletService.getWalletBalance();
      setState(() {
        _balance = balance;
      });
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _handleScanQR() async {
    final result = await Navigator.push<Map<String, String>>(
      context,
      MaterialPageRoute(
        builder: (context) => const QRScannerScreen(),
      ),
    );

    if (result != null && mounted) {
      try {
        final amount = double.tryParse(result['am'] ?? '0') ?? 0;
        final note = result['tn'] ?? 'Payment';
        final payeeUpiId = result['pa'];

        if (payeeUpiId != null) {
          await _upiService.initiateUPIPayment(
            upiId: payeeUpiId,
            amount: amount,
            note: note,
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to process payment'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showAddUPIBottomSheet() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => AddUPIBottomSheet(
        onUPIAdded: (upi) {
          setState(() {
            _upiAccounts.add(upi);
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Green Pay'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.person_circle),
          onPressed: () {
            Navigator.push(
              context,
              CupertinoPageRoute(builder: (context) => const ProfileScreen()),
            );
          },
        ),
      ),
      child: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBalanceCard(),
                  const SizedBox(height: 20),
                  _buildQuickActions(),
                  const SizedBox(height: 20),
                  _buildUPIAccounts(),
                  const SizedBox(height: 20),
                  _buildRecentTransactions(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            CupertinoColors.systemBlue,
            Color(0xFF0A84FF),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.systemBlue.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Total Balance',
            style: TextStyle(
              color: CupertinoColors.white,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '₹${NumberFormat('#,##,##0.00').format(_balance)}',
            style: const TextStyle(
              color: CupertinoColors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildBalanceActionButton(
                icon: CupertinoIcons.arrow_down,
                label: 'Add Money',
                onTap: () {
                  Navigator.push(
                    context,
                    CupertinoPageRoute(
                      builder: (context) => const AddMoneyScreen(),
                    ),
                  ).then((success) {
                    if (success == true) {
                      // Refresh balance
                      _refreshData();

                      // Show success message
                      showCupertinoDialog(
                        context: context,
                        builder: (context) => CupertinoAlertDialog(
                          title: const Text('Money Added'),
                          content: const Text(
                              'Your wallet has been successfully topped up.'),
                          actions: [
                            CupertinoDialogAction(
                              child: const Text('OK'),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                      );
                    }
                  });
                },
              ),
              _buildBalanceActionButton(
                icon: CupertinoIcons.arrow_up,
                label: 'Send Money',
                onTap: () {
                  Navigator.push(
                    context,
                    CupertinoPageRoute(
                      builder: (context) => const SendMoneyScreen(),
                    ),
                  ).then((success) {
                    if (success == true) {
                      // Refresh balance
                      _refreshData();

                      // Show success message
                      showCupertinoDialog(
                        context: context,
                        builder: (context) => CupertinoAlertDialog(
                          title: const Text('Money Sent'),
                          content: const Text(
                              'Your money has been sent successfully.'),
                          actions: [
                            CupertinoDialogAction(
                              child: const Text('OK'),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                      );
                    }
                  });
                },
              ),
              _buildBalanceActionButton(
                icon: CupertinoIcons.arrow_right_arrow_left,
                label: 'Transfer',
                onTap: () {
                  Navigator.push(
                    context,
                    CupertinoPageRoute(
                      builder: (context) => const TransferMoneyScreen(),
                    ),
                  ).then((success) {
                    if (success == true) {
                      // Refresh balance
                      _refreshData();

                      // Show success message
                      showCupertinoDialog(
                        context: context,
                        builder: (context) => CupertinoAlertDialog(
                          title: const Text('Transfer Initiated'),
                          content: const Text(
                              'Your bank transfer has been initiated and will be processed shortly.'),
                          actions: [
                            CupertinoDialogAction(
                              child: const Text('OK'),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                      );
                    }
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: CupertinoColors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: CupertinoColors.white,
              size: 20,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: CupertinoColors.white,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildQuickActionButton(
                icon: CupertinoIcons.qrcode,
                label: 'Scan & Pay',
                onTap: () {
                  Navigator.push(
                    context,
                    CupertinoPageRoute(
                        builder: (context) => const QRScannerScreen()),
                  );
                },
              ),
              _buildQuickActionButton(
                icon: CupertinoIcons.creditcard,
                label: 'Cards',
                onTap: () {
                  Navigator.push(
                    context,
                    CupertinoPageRoute(
                        builder: (context) => const CardsScreen()),
                  );
                },
              ),
              _buildQuickActionButton(
                icon: CupertinoIcons.money_dollar,
                label: 'Bills',
                onTap: () {
                  // TODO: Implement bills
                },
              ),
              // Rewards feature temporarily disabled
              /*_buildQuickActionButton(
                icon: CupertinoIcons.gift,
                label: 'Rewards',
                onTap: () {
                  // TODO: Implement rewards
                },
              ),*/
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: CupertinoColors.systemGrey6,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: CupertinoTheme.of(context).primaryColor,
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUPIAccounts() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'UPI Accounts',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                child: const Text('Add New'),
                onPressed: _showAddUPIBottomSheet,
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isLoadingUPI)
            const Center(
              child: CupertinoActivityIndicator(),
            )
          else if (_upiAccounts.isEmpty)
            _buildEmptyUPIState()
          else
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _upiAccounts.length,
                itemBuilder: (context, index) {
                  final upi = _upiAccounts[index];
                  return _buildUPICard(upi);
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyUPIState() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Icon(
            CupertinoIcons.creditcard,
            size: 40,
            color: CupertinoColors.systemGrey,
          ),
          const SizedBox(height: 12),
          const Text(
            'No UPI accounts added yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add your UPI ID or bank account to make payments',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: CupertinoColors.systemGrey,
            ),
          ),
          const SizedBox(height: 16),
          CupertinoButton.filled(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: const Text('Add UPI Account'),
            onPressed: _showAddUPIBottomSheet,
          ),
        ],
      ),
    );
  }

  Widget _buildUPICard(UPIDetails upi) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: CupertinoColors.systemGrey5,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: CupertinoColors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: CupertinoColors.systemGrey.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  _getBankIcon(upi.bankName),
                  size: 24,
                  color: CupertinoTheme.of(context).primaryColor,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  upi.bankName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            upi.upiId,
            style: const TextStyle(
              fontSize: 14,
              color: CupertinoColors.systemGrey,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  IconData _getBankIcon(String bankName) {
    // Return appropriate icon based on bank name
    switch (bankName.toLowerCase()) {
      case 'sbi':
      case 'state bank of india':
        return CupertinoIcons.building_2_fill;
      case 'hdfc':
      case 'hdfc bank':
        return CupertinoIcons.building_2_fill;
      case 'icici':
      case 'icici bank':
        return CupertinoIcons.building_2_fill;
      case 'axis':
      case 'axis bank':
        return CupertinoIcons.building_2_fill;
      default:
        return CupertinoIcons.creditcard_fill;
    }
  }

  Widget _buildRecentTransactions() {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Transactions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  child: const Text('See All'),
                  onPressed: () {
                    Navigator.push(
                      context,
                      CupertinoPageRoute(
                        builder: (context) => const TransactionsScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_isLoadingTransactions)
              const Center(
                child: CupertinoActivityIndicator(),
              )
            else if (_recentTransactions.isEmpty)
              _buildEmptyTransactionsState()
            else
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CupertinoScrollbar(
                    child: ListView.separated(
                      padding: EdgeInsets.zero,
                      itemCount: _recentTransactions.length,
                      separatorBuilder: (context, index) => Container(
                        height: 1,
                        color: CupertinoColors.systemGrey5,
                      ),
                      itemBuilder: (context, index) {
                        final transaction = _recentTransactions[index];
                        return _buildTransactionItem(transaction);
                      },
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyTransactionsState() {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              CupertinoIcons.time,
              size: 48,
              color: CupertinoColors.systemGrey,
            ),
            const SizedBox(height: 16),
            const Text(
              'No transactions yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your recent transactions will appear here',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: CupertinoColors.systemGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionItem(Transaction transaction) {
    final isIncoming = transaction.type == TransactionType.credit;
    final amountColor =
        isIncoming ? CupertinoColors.systemGreen : CupertinoColors.systemRed;
    final amountPrefix = isIncoming ? '+' : '-';

    return CupertinoListTile(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isIncoming
              ? CupertinoColors.systemGreen.withOpacity(0.1)
              : CupertinoColors.systemRed.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(
          isIncoming
              ? CupertinoIcons.arrow_down_left
              : CupertinoIcons.arrow_up_right,
          color: amountColor,
          size: 20,
        ),
      ),
      title: Text(
        transaction.title,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        DateFormat('dd MMM, yyyy • hh:mm a').format(transaction.timestamp),
        style: const TextStyle(
          fontSize: 12,
          color: CupertinoColors.systemGrey,
        ),
      ),
      trailing: Text(
        '$amountPrefix₹${NumberFormat('#,##,##0.00').format(transaction.amount)}',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: amountColor,
        ),
      ),
    );
  }

  Widget _buildCardsPage() {
    return const Center(
      child: Text('Cards Page - Coming Soon'),
    );
  }

  Widget _buildTransactionsPage() {
    return const TransactionsScreen();
  }

  Future<void> _refreshData() async {
    setState(() {
      _isLoadingUPI = true;
      _isLoadingTransactions = true;
    });

    await Future.wait([
      _loadUPIAccounts(),
      _loadTransactions(),
      _loadBalance(),
    ]);
  }
}
