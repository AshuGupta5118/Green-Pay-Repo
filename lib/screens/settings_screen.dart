import 'package:flutter/cupertino.dart';
import 'package:green_pay/models/user_settings.dart';
import 'package:green_pay/services/biometric_service.dart';
import 'package:green_pay/theme/app_theme.dart';
import 'package:green_pay/providers/theme_provider.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  late final BiometricService _biometricService;
  bool _isBiometricAvailable = false;
  UserSettings _settings = UserSettings();
  bool _isLoading = true;

  // Animation controllers
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _biometricService = BiometricService();
    _loadSettings();

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

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.1, 0.7, curve: Curves.easeOut),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);

    try {
      _isBiometricAvailable = await _biometricService.isBiometricAvailable();
      // TODO: Load user settings from API
      setState(() {
        _settings = _settings.copyWith(
          isBiometricAvailable: _isBiometricAvailable,
        );
      });
    } finally {
      setState(() => _isLoading = false);
      // Start animations after loading
      _animationController.forward();
    }
  }

  Future<void> _toggleBiometric(bool value) async {
    if (value && !await _biometricService.authenticate()) {
      return;
    }

    setState(() {
      _settings = _settings.copyWith(biometricEnabled: value);
    });

    // TODO: Save settings to API
  }

  Future<void> _toggleNotifications(bool value) async {
    setState(() {
      _settings = _settings.copyWith(notificationsEnabled: value);
    });

    // TODO: Save settings to API
  }

  void _toggleNotificationPreference(String key, bool value) {
    setState(() {
      final newPreferences =
          Map<String, bool>.from(_settings.notificationPreferences);
      newPreferences[key] = value;
      _settings = _settings.copyWith(notificationPreferences: newPreferences);
    });

    // TODO: Save settings to API
  }

  void _updateThemeMode(String? mode) {
    if (mode == null) return;

    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    switch (mode) {
      case 'system':
        // Use system setting
        break;
      case 'light':
        themeProvider.setTheme(false);
        break;
      case 'dark':
        themeProvider.setTheme(true);
        break;
    }

    // TODO: Save settings to API
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const CupertinoPageScaffold(
        child: Center(child: CupertinoActivityIndicator()),
      );
    }

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Settings'),
      ),
      child: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: ListView(
              children: [
                const SizedBox(height: 10),
                _buildSectionHeader('Account & Security'),
                if (_settings.isBiometricAvailable)
                  _buildToggleRow(
                    'Biometric Authentication',
                    'Use Face ID or Touch ID to unlock the app',
                    _settings.biometricEnabled,
                    _toggleBiometric,
                  ),
                _buildDivider(),
                _buildSectionHeader('Notifications'),
                _buildToggleRow(
                  'Push Notifications',
                  'Receive notifications about transactions and updates',
                  _settings.notificationsEnabled,
                  _toggleNotifications,
                ),
                if (_settings.notificationsEnabled) ...[
                  _buildSectionHeader('Notification Preferences'),
                  _buildToggleRow(
                    'Transactions',
                    'Get notified about new transactions',
                    _settings.notificationPreferences['transactions'] ?? true,
                    (value) =>
                        _toggleNotificationPreference('transactions', value),
                  ),
                  _buildToggleRow(
                    'Security Alerts',
                    'Get notified about security-related events',
                    _settings.notificationPreferences['security'] ?? true,
                    (value) => _toggleNotificationPreference('security', value),
                  ),
                  _buildToggleRow(
                    'Promotions',
                    'Get notified about offers and promotions',
                    _settings.notificationPreferences['promotions'] ?? false,
                    (value) =>
                        _toggleNotificationPreference('promotions', value),
                  ),
                ],
                _buildDivider(),
                _buildSectionHeader('Appearance'),
                _buildThemeSelector(),
                _buildDivider(),
                _buildSectionHeader('About'),
                _buildNavigationRow(
                  'About Green Pay',
                  () {
                    // TODO: Navigate to about screen
                  },
                ),
                _buildNavigationRow(
                  'Help & Support',
                  () {
                    // TODO: Navigate to help screen
                  },
                ),
                _buildNavigationRow(
                  'Privacy Policy',
                  () {
                    // TODO: Open privacy policy
                  },
                ),
                _buildNavigationRow(
                  'Terms of Service',
                  () {
                    // TODO: Open terms of service
                  },
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: CupertinoColors.secondaryLabel,
          letterSpacing: -0.08,
        ),
      ),
    );
  }

  Widget _buildToggleRow(
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
  ) {
    return CupertinoListTile(
      title: Text(title),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 14,
          color: CupertinoColors.secondaryLabel,
        ),
      ),
      trailing: CupertinoSwitch(
        value: value,
        onChanged: onChanged,
        activeColor: AppTheme.primaryColor,
      ),
    );
  }

  Widget _buildNavigationRow(String title, VoidCallback onTap) {
    return CupertinoListTile(
      title: Text(title),
      trailing: const CupertinoListTileChevron(),
      onTap: onTap,
    );
  }

  Widget _buildThemeSelector() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final currentTheme = themeProvider.isDarkMode ? 'dark' : 'light';

    return CupertinoListTile(
      title: const Text('Theme'),
      trailing: CupertinoButton(
        padding: EdgeInsets.zero,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _getThemeDisplayName(currentTheme),
              style: const TextStyle(
                color: CupertinoColors.secondaryLabel,
              ),
            ),
            const SizedBox(width: 5),
            const Icon(
              CupertinoIcons.chevron_down,
              size: 14,
              color: CupertinoColors.secondaryLabel,
            ),
          ],
        ),
        onPressed: () => _showThemeActionSheet(context, currentTheme),
      ),
    );
  }

  String _getThemeDisplayName(String theme) {
    switch (theme) {
      case 'system':
        return 'System';
      case 'light':
        return 'Light';
      case 'dark':
        return 'Dark';
      default:
        return 'System';
    }
  }

  void _showThemeActionSheet(BuildContext context, String currentTheme) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: const Text('Select Theme'),
        message: const Text('Choose your preferred app appearance'),
        actions: <CupertinoActionSheetAction>[
          CupertinoActionSheetAction(
            isDefaultAction: currentTheme == 'system',
            onPressed: () {
              Navigator.pop(context);
              _updateThemeMode('system');
            },
            child: const Text('System'),
          ),
          CupertinoActionSheetAction(
            isDefaultAction: currentTheme == 'light',
            onPressed: () {
              Navigator.pop(context);
              _updateThemeMode('light');
            },
            child: const Text('Light'),
          ),
          CupertinoActionSheetAction(
            isDefaultAction: currentTheme == 'dark',
            onPressed: () {
              Navigator.pop(context);
              _updateThemeMode('dark');
            },
            child: const Text('Dark'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          child: const Text('Cancel'),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 0.5,
      color: CupertinoColors.separator,
    );
  }
}
