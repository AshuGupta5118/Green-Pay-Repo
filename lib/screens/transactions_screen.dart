import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import 'package:fl_chart/fl_chart.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen>
    with SingleTickerProviderStateMixin {
  final _databaseService = DatabaseService();
  late TabController _tabController;
  List<Transaction> _transactions = [];
  Map<String, double> _monthlySpending = {};
  bool _isLoading = true;
  TransactionType? _selectedType;
  TransactionCategory? _selectedCategory;

  // Animation controllers
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();

    // Initialize animations
    _animationController = AnimationController(
      duration: AppTheme.mediumAnimation,
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOut),
      ),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.1, 0.7, curve: Curves.easeOut),
      ),
    );

    // Start the animation
    _animationController.forward();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final transactions = await _databaseService.getTransactions();
      final monthlySpending = await _databaseService.getMonthlySpending();

      setState(() {
        _transactions = transactions;
        _monthlySpending = monthlySpending;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        _showErrorMessage(e.toString());
      }
    }
  }

  void _showErrorMessage(String message) {
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

  List<Transaction> get _filteredTransactions {
    return _transactions.where((tx) {
      if (_selectedType != null && tx.type != _selectedType) {
        return false;
      }
      if (_selectedCategory != null && tx.category != _selectedCategory) {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Transactions'),
      ),
      child: SafeArea(
        child: _isLoading
            ? const Center(child: CupertinoActivityIndicator())
            : FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Column(
                      children: [
                        _buildTabBar(),
                        Expanded(
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              _buildTransactionsList(),
                              _buildAnalyticsView(),
                            ],
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

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      height: 44,
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey5,
        borderRadius: BorderRadius.circular(8),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: CupertinoColors.activeGreen,
        ),
        labelColor: CupertinoColors.white,
        unselectedLabelColor: CupertinoColors.systemGrey,
        tabs: const [
          Tab(text: 'Transactions'),
          Tab(text: 'Analytics'),
        ],
      ),
    );
  }

  Widget _buildTransactionsList() {
    if (_transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.money_dollar_circle,
              size: 64,
              color: CupertinoColors.systemGrey,
            ),
            const SizedBox(height: 16),
            const Text(
              'No transactions yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: CupertinoColors.systemGrey,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your transactions will appear here',
              style: TextStyle(
                color: CupertinoColors.systemGrey,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        _buildFilters(),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _filteredTransactions.length,
            itemBuilder: (context, index) {
              final transaction = _filteredTransactions[index];
              return _buildTransactionItem(transaction);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: CupertinoButton(
              padding: EdgeInsets.zero,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey6,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: CupertinoColors.systemGrey5),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _selectedType == null
                          ? 'All Types'
                          : _selectedType.toString().split('.').last,
                      style: const TextStyle(
                        color: CupertinoColors.label,
                        fontSize: 14,
                      ),
                    ),
                    const Icon(
                      CupertinoIcons.chevron_down,
                      size: 14,
                      color: CupertinoColors.systemGrey,
                    ),
                  ],
                ),
              ),
              onPressed: _showTypeFilterSheet,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: CupertinoButton(
              padding: EdgeInsets.zero,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey6,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: CupertinoColors.systemGrey5),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _selectedCategory == null
                          ? 'All Categories'
                          : _selectedCategory.toString().split('.').last,
                      style: const TextStyle(
                        color: CupertinoColors.label,
                        fontSize: 14,
                      ),
                    ),
                    const Icon(
                      CupertinoIcons.chevron_down,
                      size: 14,
                      color: CupertinoColors.systemGrey,
                    ),
                  ],
                ),
              ),
              onPressed: _showCategoryFilterSheet,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalytics() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMonthlySpendingChart(),
          const SizedBox(height: 32),
          _buildCategoryBreakdown(),
        ],
      ),
    );
  }

  Widget _buildMonthlySpendingChart() {
    final List<FlSpot> spots = [];
    final sortedMonths = _monthlySpending.keys.toList()..sort();

    for (var i = 0; i < sortedMonths.length; i++) {
      spots.add(FlSpot(
        i.toDouble(),
        _monthlySpending[sortedMonths[i]]!,
      ));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Monthly Spending',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(show: false),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      return Text('₹${value.toInt()}');
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      if (value.toInt() >= 0 &&
                          value.toInt() < sortedMonths.length) {
                        final month = sortedMonths[value.toInt()];
                        return Text(month.split('-')[1]);
                      }
                      return const Text('');
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: Colors.black,
                  barWidth: 3,
                  dotData: FlDotData(show: true),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryBreakdown() {
    final Map<TransactionCategory, double> categoryTotals = {};
    double total = 0;

    for (var transaction in _transactions) {
      if (transaction.type == TransactionType.debit) {
        categoryTotals[transaction.category] =
            (categoryTotals[transaction.category] ?? 0) + transaction.amount;
        total += transaction.amount;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category Breakdown',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        ...categoryTotals.entries.map((entry) {
          final percentage = (entry.value / total * 100).toStringAsFixed(1);
          return ListTile(
            leading: Icon(_getCategoryIcon(entry.key)),
            title: Text(entry.key.toString().split('.').last),
            trailing: Text(
              '${_formatAmount(entry.value, TransactionType.debit)} ($percentage%)',
            ),
          );
        }),
      ],
    );
  }

  IconData _getCategoryIcon(TransactionCategory category) {
    switch (category) {
      case TransactionCategory.food:
        return CupertinoIcons.cart_fill;
      case TransactionCategory.shopping:
        return CupertinoIcons.shopping_cart;
      case TransactionCategory.transport:
        return CupertinoIcons.car_fill;
      case TransactionCategory.entertainment:
        return CupertinoIcons.film_fill;
      case TransactionCategory.bills:
        return CupertinoIcons.doc_text_fill;
      case TransactionCategory.others:
        return CupertinoIcons.money_dollar;
    }
  }

  String _formatAmount(double amount, TransactionType type) {
    final format = NumberFormat.currency(
      symbol: '₹',
      locale: 'en_IN',
      decimalDigits: 2,
    );
    return '${type == TransactionType.credit ? '+' : '-'} ${format.format(amount)}';
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM d, y').format(date);
  }

  Widget _buildAnalyticsView() {
    return _buildAnalytics();
  }

  Widget _buildTransactionItem(Transaction transaction) {
    final isCredit = transaction.type == TransactionType.credit;
    final formattedAmount =
        NumberFormat.currency(symbol: '₹').format(transaction.amount);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.systemGrey5.withOpacity(0.5),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isCredit
                    ? CupertinoColors.activeGreen.withOpacity(0.1)
                    : CupertinoColors.systemRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getCategoryIcon(transaction.category),
                color: isCredit
                    ? CupertinoColors.activeGreen
                    : CupertinoColors.systemRed,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(transaction.timestamp),
                    style: TextStyle(
                      color: CupertinoColors.systemGrey,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              isCredit ? '+$formattedAmount' : '-$formattedAmount',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: isCredit
                    ? CupertinoColors.activeGreen
                    : CupertinoColors.systemRed,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTypeFilterSheet() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('Filter by Type'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              setState(() {
                _selectedType = null;
              });
              Navigator.pop(context);
            },
            child: const Text('All Types'),
          ),
          ...TransactionType.values.map(
            (type) => CupertinoActionSheetAction(
              onPressed: () {
                setState(() {
                  _selectedType = type;
                });
                Navigator.pop(context);
              },
              child: Text(type.toString().split('.').last),
            ),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          isDestructiveAction: true,
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  void _showCategoryFilterSheet() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('Filter by Category'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              setState(() {
                _selectedCategory = null;
              });
              Navigator.pop(context);
            },
            child: const Text('All Categories'),
          ),
          ...TransactionCategory.values.map(
            (category) => CupertinoActionSheetAction(
              onPressed: () {
                setState(() {
                  _selectedCategory = category;
                });
                Navigator.pop(context);
              },
              child: Text(category.toString().split('.').last),
            ),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          isDestructiveAction: true,
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }
}
