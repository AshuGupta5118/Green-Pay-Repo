import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import '../utils/secure_storage.dart';

class SecurityService {
  static final SecurityService _instance = SecurityService._internal();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final _storage = SecureStorage();
  late Key _encryptionKey;
  late IV _iv;
  late Encrypter _encrypter;
  bool _isInitialized = false;
  final LocalAuthentication _localAuth = LocalAuthentication();

  static const _biometricEnabledKey = 'biometric_enabled';
  static const _pinCodeKey = 'pin_code';

  factory SecurityService() {
    return _instance;
  }

  SecurityService._internal();

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Try to load existing encryption key and IV
      String? storedKey = await _secureStorage.read(key: 'encryption_key');
      String? storedIV = await _secureStorage.read(key: 'encryption_iv');

      if (storedKey == null || storedIV == null) {
        // Generate new key and IV if not found
        final key = Key.fromSecureRandom(32);
        final iv = IV.fromSecureRandom(16);

        // Store them securely
        await _secureStorage.write(
            key: 'encryption_key', value: base64.encode(key.bytes));
        await _secureStorage.write(
            key: 'encryption_iv', value: base64.encode(iv.bytes));

        _encryptionKey = key;
        _iv = iv;
      } else {
        // Use existing key and IV
        _encryptionKey = Key(base64.decode(storedKey));
        _iv = IV(base64.decode(storedIV));
      }

      _encrypter = Encrypter(AES(_encryptionKey));
      _isInitialized = true;
    } catch (e) {
      throw Exception('Failed to initialize SecurityService: $e');
    }
  }

  String encrypt(String data) {
    if (!_isInitialized) throw Exception('SecurityService not initialized');
    return _encrypter.encrypt(data, iv: _iv).base64;
  }

  String decrypt(String encryptedData) {
    if (!_isInitialized) throw Exception('SecurityService not initialized');
    try {
      final encrypted = Encrypted.fromBase64(encryptedData);
      return _encrypter.decrypt(encrypted, iv: _iv);
    } catch (e) {
      throw Exception('Failed to decrypt data: $e');
    }
  }

  String hashData(String data) {
    final bytes = utf8.encode(data);
    return sha256.convert(bytes).toString();
  }

  bool verifyHash(String data, String hash) {
    return hashData(data) == hash;
  }

  String generateSecureToken() {
    final random = Random.secure();
    final values = List<int>.generate(32, (i) => random.nextInt(256));
    return base64Url.encode(values);
  }

  bool isStrongPassword(String password) {
    if (password.length < 8) return false;

    bool hasUppercase = password.contains(RegExp(r'[A-Z]'));
    bool hasLowercase = password.contains(RegExp(r'[a-z]'));
    bool hasDigits = password.contains(RegExp(r'[0-9]'));
    bool hasSpecialChars = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

    return hasUppercase && hasLowercase && hasDigits && hasSpecialChars;
  }

  Future<void> storeSecureData(String key, String value) async {
    if (!_isInitialized) throw Exception('SecurityService not initialized');
    final encryptedValue = encrypt(value);
    await _secureStorage.write(key: key, value: encryptedValue);
  }

  Future<String?> getSecureData(String key) async {
    if (!_isInitialized) throw Exception('SecurityService not initialized');
    final encryptedValue = await _secureStorage.read(key: key);
    if (encryptedValue == null) return null;
    return decrypt(encryptedValue);
  }

  Future<void> removeSecureData(String key) async {
    await _secureStorage.delete(key: key);
  }

  Future<void> clearSecureStorage() async {
    await _secureStorage.deleteAll();
    _isInitialized = false;
  }

  // Check if device supports biometric authentication
  Future<bool> isBiometricAvailable() async {
    try {
      return await _localAuth.canCheckBiometrics &&
          await _localAuth.isDeviceSupported();
    } on PlatformException catch (_) {
      return false;
    }
  }

  // Enable or disable biometric authentication
  Future<void> setBiometricEnabled(bool enabled) async {
    await _storage.setBiometricEnabled(enabled);
  }

  // Check if biometric authentication is enabled
  Future<bool> isBiometricEnabled() async {
    return await _storage.getBiometricEnabled();
  }

  // Authenticate using biometrics
  Future<bool> authenticateWithBiometrics() async {
    try {
      return await _localAuth.authenticate(
        localizedReason: 'Authenticate to access your account',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } on PlatformException catch (_) {
      return false;
    }
  }

  // Set PIN code
  Future<void> setPinCode(String pinCode) async {
    await _secureStorage.write(key: _pinCodeKey, value: pinCode);
  }

  // Verify PIN code
  Future<bool> verifyPinCode(String pinCode) async {
    final storedPinCode = await _secureStorage.read(key: _pinCodeKey);
    return storedPinCode == pinCode;
  }

  // Check if PIN code is set
  Future<bool> isPinCodeSet() async {
    final pinCode = await _secureStorage.read(key: _pinCodeKey);
    return pinCode != null && pinCode.isNotEmpty;
  }

  // Clear all security settings
  Future<void> clearSecuritySettings() async {
    await _secureStorage.delete(key: _biometricEnabledKey);
    await _secureStorage.delete(key: _pinCodeKey);
  }
}
