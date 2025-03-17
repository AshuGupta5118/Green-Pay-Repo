import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../services/upi_service.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';
import 'login_screen.dart';
import 'package:local_auth/local_auth.dart';
import '../services/biometric_auth_service.dart';
import '../utils/secure_storage.dart';
import 'help/biometric_help_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _authService = AuthService();
  final _databaseService = DatabaseService();
  final _upiService = UPIService();
  final _biometricService = BiometricAuthService();
  final _secureStorage = SecureStorage();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _isBiometricEnabled = false;
  bool _isBiometricAvailable = false;
  List<BiometricType> _availableBiometrics = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadBiometricSettings();
  }

  Future<void> _loadUserData() {
    final user = _authService.currentUser;
    if (user != null) {
      _nameController.text = user.name ?? '';
      _emailController.text = user.email ?? '';
    }
    return Future.value();
  }

  Future<void> _loadBiometricSettings() async {
    final isAvailable = await _biometricService.isBiometricAvailable();
    final isEnabled = await _secureStorage.getBiometricEnabled();
    final availableBiometrics =
        await _biometricService.getAvailableBiometrics();

    if (mounted) {
      setState(() {
        _isBiometricAvailable = isAvailable;
        _isBiometricEnabled = isEnabled;
        _availableBiometrics = availableBiometrics;
      });
    }
  }

  Future<void> _updateProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _authService.updateProfile(
        name: _nameController.text,
        email: _emailController.text,
      );

      if (mounted) {
        _showSuccessMessage('Profile updated successfully');
      }
    } catch (e) {
      if (mounted) {
        _showErrorMessage('Failed to update profile');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _logout() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await Future.wait([
        _authService.logout(),
        _databaseService.clearTransactions(),
        _upiService.clearUPIAccounts(),
      ]);

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          CupertinoPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorMessage('Failed to logout');
      }
    }
  }

  Future<void> _toggleBiometric(bool value) async {
    if (!_isBiometricAvailable) {
      _showBiometricNotAvailableDialog();
      return;
    }

    try {
      if (value) {
        // Verify biometric before enabling
        final authenticated =
            await _biometricService.authenticateWithBiometrics();
        if (!authenticated) {
          if (mounted) {
            setState(() => _isBiometricEnabled = false);
          }
          return;
        }
      }

      await _secureStorage.setBiometricEnabled(value);
      if (mounted) {
        setState(() => _isBiometricEnabled = value);
        if (value) {
          _showSuccessMessage('Biometric authentication enabled');
        } else {
          _showSuccessMessage('Biometric authentication disabled');
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog(
            'Failed to ${value ? 'enable' : 'disable'} biometric authentication');
        setState(() => _isBiometricEnabled = !value);
      }
    }
  }

  void _showBiometricNotAvailableDialog() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Biometric Not Available'),
        content: const Text(
          'Your device does not support biometric authentication or no biometrics are enrolled.',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.pop(context),
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

  void _showSuccessMessage(String message) {
    _showMessage(message, CupertinoColors.activeGreen);
  }

  void _showErrorMessage(String message) {
    _showMessage(message, CupertinoColors.destructiveRed);
  }

  void _showMessage(String message, Color color) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
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

  void _showLogoutConfirmation() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(context);
              _logout();
            },
            child: const Text('Logout'),
          ),
          CupertinoDialogAction(
            child: const Text('Cancel'),
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
        middle: Text('Profile'),
      ),
      child: SafeArea(
        child: _isLoading
            ? const Center(child: CupertinoActivityIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Stack(
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: CupertinoColors.systemGrey5,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              CupertinoIcons.person_fill,
                              size: 50,
                              color: CupertinoColors.systemGrey,
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: CupertinoColors.activeBlue,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                CupertinoIcons.pencil,
                                size: 20,
                                color: CupertinoColors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Personal Information',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _nameController,
                      label: 'Name',
                      prefix: const Icon(CupertinoIcons.person),
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _emailController,
                      label: 'Email',
                      prefix: const Icon(CupertinoIcons.mail),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 32),
                    CustomButton(
                      text: 'Update Profile',
                      onPressed: _isLoading ? null : _updateProfile,
                      isLoading: _isLoading,
                      isFullWidth: true,
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Security',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildBiometricSettingsItem(),
                    const SizedBox(height: 32),
                    CustomButton(
                      text: 'Logout',
                      onPressed: _isLoading ? null : _showLogoutConfirmation,
                      type: ButtonType.destructive,
                      isFullWidth: true,
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildBiometricSettingsItem() {
    final String biometricType =
        _availableBiometrics.contains(BiometricType.face)
            ? 'Face ID'
            : _availableBiometrics.contains(BiometricType.fingerprint)
                ? 'Fingerprint'
                : 'Biometric';

    final String subtitle = _isBiometricAvailable
        ? 'Use $biometricType to quickly and securely access your account'
        : 'Your device does not support biometric authentication';

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        CupertinoPageRoute(
          builder: (context) => const BiometricHelpScreen(),
        ),
      ),
      child: _buildSettingsItem(
        icon: CupertinoIcons.lock_shield,
        title: '$biometricType Authentication',
        subtitle: subtitle,
        trailing: _isBiometricAvailable
            ? Semantics(
                label: _isBiometricEnabled
                    ? 'Disable $biometricType authentication'
                    : 'Enable $biometricType authentication',
                child: CupertinoSwitch(
                  value: _isBiometricEnabled,
                  onChanged: _toggleBiometric,
                ),
              )
            : Semantics(
                label: 'Biometric authentication not available',
                child: const Icon(
                  CupertinoIcons.xmark_circle,
                  color: CupertinoColors.systemRed,
                ),
              ),
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required Widget trailing,
  }) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: null, // Disable tap since we're using the switch
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey6,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: CupertinoTheme.of(context).primaryColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: CupertinoColors.systemGrey,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }
}
