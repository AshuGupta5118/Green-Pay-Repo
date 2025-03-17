import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:green_pay/models/bill_provider.dart';
import 'package:green_pay/services/bills_service.dart';
import 'package:green_pay/services/wallet_service.dart';
import 'package:green_pay/screens/bill_payment_screen.dart';

class BillsScreen extends StatefulWidget {
  const BillsScreen({Key? key}) : super(key: key);

  @override
  State<BillsScreen> createState() => _BillsScreenState();
}

class _BillsScreenState extends State<BillsScreen>
    with SingleTickerProviderStateMixin {
  final BillsService _billsService = BillsService();
  final WalletService _walletService = WalletService();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isLoading = true;
  String? _errorMessage;
  double _walletBalance = 0.0;
  List<String> _categories = [];
  String? _selectedCategory;
  List<BillProvider> _providers = [];

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

    _loadData();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final categories = await _billsService.getBillCategories();
      final balance = await _walletService.getWalletBalance();

      setState(() {
        _categories = categories;
        _walletBalance = balance;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load data: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadProviders(String category) async {
    setState(() {
      _isLoading = true;
      _selectedCategory = category;
    });

    try {
      final providers = await _billsService.getBillProviders(category);
      setState(() {
        _providers = providers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load providers: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _selectProvider(BillProvider provider) {
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => BillPaymentScreen(
          category: _selectedCategory!,
          provider: provider,
          walletBalance: _walletBalance,
        ),
      ),
    ).then((success) {
      if (success == true) {
        // Refresh wallet balance
        _loadData();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Pay Bills'),
        border: null,
        leading: _selectedCategory != null
            ? CupertinoButton(
                padding: EdgeInsets.zero,
                child: const Icon(CupertinoIcons.back),
                onPressed: () {
                  setState(() {
                    _selectedCategory = null;
                    _providers = [];
                  });
                },
              )
            : null,
      ),
      child: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: _isLoading
                ? const Center(child: CupertinoActivityIndicator())
                : _errorMessage != null
                    ? _buildErrorState()
                    : _selectedCategory == null
                        ? _buildCategoriesGrid()
                        : _buildProvidersList(),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              CupertinoIcons.exclamationmark_circle,
              size: 48,
              color: CupertinoColors.systemRed,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: CupertinoColors.systemGrey,
              ),
            ),
            const SizedBox(height: 24),
            CupertinoButton.filled(
              child: const Text('Try Again'),
              onPressed: _loadData,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriesGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select Bill Category',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Available balance: ₹${_walletBalance.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 14,
                  color: CupertinoColors.systemGrey,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              final category = _categories[index];
              return _buildCategoryCard(category);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryCard(String category) {
    IconData icon;
    Color color;

    switch (category.toLowerCase()) {
      case 'electricity':
        icon = CupertinoIcons.bolt_fill;
        color = CupertinoColors.systemYellow;
        break;
      case 'water':
        icon = CupertinoIcons.drop_fill;
        color = CupertinoColors.systemBlue;
        break;
      case 'gas':
        icon = CupertinoIcons.flame_fill;
        color = CupertinoColors.systemOrange;
        break;
      case 'internet':
        icon = CupertinoIcons.wifi;
        color = CupertinoColors.systemGreen;
        break;
      case 'mobile':
        icon = CupertinoIcons.device_phone_portrait;
        color = CupertinoColors.systemPurple;
        break;
      case 'dth':
        icon = CupertinoIcons.tv_fill;
        color = CupertinoColors.systemIndigo;
        break;
      case 'insurance':
        icon = CupertinoIcons.shield_fill;
        color = CupertinoColors.systemTeal;
        break;
      case 'landline':
        icon = CupertinoIcons.phone_fill;
        color = CupertinoColors.systemRed;
        break;
      default:
        icon = CupertinoIcons.doc_text_fill;
        color = CupertinoColors.systemGrey;
    }

    return GestureDetector(
      onTap: () => _loadProviders(category),
      child: Container(
        decoration: BoxDecoration(
          color: CupertinoColors.systemGrey6,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: CupertinoColors.systemGrey.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 32,
                color: color,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              category,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProvidersList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$_selectedCategory Providers',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Select your service provider',
                style: TextStyle(
                  fontSize: 14,
                  color: CupertinoColors.systemGrey,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _providers.isEmpty
              ? _buildEmptyProvidersState()
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _providers.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final provider = _providers[index];
                    return _buildProviderItem(provider);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyProvidersState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            CupertinoIcons.search,
            size: 48,
            color: CupertinoColors.systemGrey,
          ),
          const SizedBox(height: 16),
          const Text(
            'No providers found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Try selecting a different category',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: CupertinoColors.systemGrey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProviderItem(BillProvider provider) {
    return CupertinoListTile(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: CupertinoColors.systemGrey6,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: provider.logoUrl != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    provider.logoUrl!,
                    width: 40,
                    height: 40,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      CupertinoIcons.building_2_fill,
                      size: 24,
                      color: CupertinoColors.systemGrey,
                    ),
                  ),
                )
              : const Icon(
                  CupertinoIcons.building_2_fill,
                  size: 24,
                  color: CupertinoColors.systemGrey,
                ),
        ),
      ),
      title: Text(
        provider.name,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: provider.description != null
          ? Text(
              provider.description!,
              style: const TextStyle(
                fontSize: 14,
                color: CupertinoColors.systemGrey,
              ),
            )
          : null,
      trailing: const Icon(CupertinoIcons.chevron_right),
      onTap: () => _selectProvider(provider),
    );
  }
}
