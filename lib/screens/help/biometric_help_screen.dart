import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import '../../services/biometric_auth_service.dart';

class BiometricHelpScreen extends StatefulWidget {
  const BiometricHelpScreen({super.key});

  @override
  State<BiometricHelpScreen> createState() => _BiometricHelpScreenState();
}

class _BiometricHelpScreenState extends State<BiometricHelpScreen> {
  final _biometricService = BiometricAuthService();
  List<BiometricType> _availableBiometrics = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBiometrics();
  }

  Future<void> _loadBiometrics() async {
    final biometrics = await _biometricService.getAvailableBiometrics();
    if (mounted) {
      setState(() {
        _availableBiometrics = biometrics;
        _isLoading = false;
      });
    }
  }

  String _getBiometricName() {
    if (_availableBiometrics.contains(BiometricType.face)) {
      return 'Face ID';
    } else if (_availableBiometrics.contains(BiometricType.fingerprint)) {
      return 'Fingerprint';
    } else {
      return 'Biometric Authentication';
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('${_getBiometricName()} Help'),
      ),
      child: SafeArea(
        child: _isLoading
            ? const Center(child: CupertinoActivityIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 24),
                    _buildWhatIsBiometric(),
                    const SizedBox(height: 24),
                    _buildHowToUse(),
                    const SizedBox(height: 24),
                    _buildTroubleshooting(),
                    const SizedBox(height: 24),
                    _buildPrivacyInfo(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          _availableBiometrics.contains(BiometricType.face)
              ? CupertinoIcons.lock_shield_fill
              : CupertinoIcons.lock_shield,
          size: 48,
          color: CupertinoColors.activeBlue,
        ),
        const SizedBox(height: 16),
        Text(
          'About ${_getBiometricName()}',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${_getBiometricName()} provides a secure and convenient way to access your Green Pay account without entering your PIN.',
          style: const TextStyle(
            fontSize: 16,
            color: CupertinoColors.systemGrey,
          ),
        ),
      ],
    );
  }

  Widget _buildWhatIsBiometric() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'What is Biometric Authentication?',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _availableBiometrics.contains(BiometricType.face)
              ? 'Face ID uses the TrueDepth camera to accurately map the geometry of your face. Each time you unlock your phone, the camera detects your face, even in the dark.'
              : 'Fingerprint authentication uses your device\'s fingerprint sensor to verify your identity. It captures high-resolution images of your fingerprint\'s unique pattern.',
          style: const TextStyle(
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Biometric data is stored securely on your device and is never sent to our servers.',
          style: TextStyle(
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildHowToUse() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'How to Enable',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '1. Go to Profile screen\n'
          '2. Find the ${_getBiometricName()} Authentication option\n'
          '3. Toggle the switch to enable\n'
          '4. Authenticate using your ${_getBiometricName()} when prompted',
          style: const TextStyle(
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildTroubleshooting() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Troubleshooting',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _availableBiometrics.contains(BiometricType.face)
              ? '• Make sure your face is not covered\n'
                  '• Ensure there is adequate lighting\n'
                  '• Hold your device at eye level\n'
                  '• Remove sunglasses or other accessories that cover your face\n'
                  '• If Face ID fails repeatedly, you\'ll need to enter your PIN'
              : '• Make sure your finger is clean and dry\n'
                  '• Place your finger flat on the sensor\n'
                  '• Don\'t move your finger while scanning\n'
                  '• Try using a different finger if registered\n'
                  '• If fingerprint fails repeatedly, you\'ll need to enter your PIN',
          style: const TextStyle(
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildPrivacyInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Privacy & Security',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          '• Your biometric data never leaves your device\n'
          '• We don\'t store any biometric information on our servers\n'
          '• You can disable biometric authentication at any time\n'
          '• Biometric data is encrypted and protected by your device\'s security features',
          style: TextStyle(
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}
