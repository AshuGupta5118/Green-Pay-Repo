import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';
import '../utils/secure_storage.dart';
import 'analytics_service.dart';

class BiometricAuthService {
  static final BiometricAuthService _instance =
      BiometricAuthService._internal();
  factory BiometricAuthService() => _instance;

  // Private constructor for singleton
  BiometricAuthService._internal()
      : _localAuth = LocalAuthentication(),
        _secureStorage = SecureStorage(),
        _analyticsService = AnalyticsService();

  final LocalAuthentication _localAuth;
  final SecureStorage _secureStorage;
  final AnalyticsService _analyticsService;

  // List of operations that require biometric verification
  static const _sensitiveOperations = [
    'getAuthToken',
    'getUserProfile',
    'getRefreshToken',
  ];

  Future<bool> isBiometricAvailable() async {
    try {
      final isAvailable = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      final result = isAvailable && isDeviceSupported;

      if (!result) {
        await _analyticsService.logEvent(
          AnalyticsService.biometricAuthNotAvailable,
          parameters: {
            'is_available': isAvailable,
            'is_device_supported': isDeviceSupported,
          },
        );
      }

      return result;
    } on PlatformException catch (e) {
      await _analyticsService.trackBiometricAuthFailure(
        'unknown',
        'Error checking availability: ${e.message}',
      );
      return false;
    }
  }

  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      final biometrics = await _localAuth.getAvailableBiometrics();

      await _analyticsService.logEvent(
        'biometric_types_available',
        parameters: {
          'types': biometrics.map((b) => b.toString()).toList(),
        },
      );

      return biometrics;
    } on PlatformException catch (e) {
      await _analyticsService.trackBiometricAuthFailure(
        'unknown',
        'Error getting available biometrics: ${e.message}',
      );
      return [];
    }
  }

  Future<bool> authenticateWithBiometrics() async {
    try {
      final biometrics = await getAvailableBiometrics();
      final biometricType = _getBiometricTypeString(biometrics);

      final result = await _localAuth.authenticate(
        localizedReason: 'Please authenticate to access secure data',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      if (result) {
        await _analyticsService.trackBiometricAuthSuccess(biometricType);
      } else {
        await _analyticsService.trackBiometricAuthCancelled(biometricType);
      }

      return result;
    } on PlatformException catch (e) {
      final biometrics = await getAvailableBiometrics();
      final biometricType = _getBiometricTypeString(biometrics);

      await _analyticsService.trackBiometricAuthFailure(
        biometricType,
        'Error during authentication: ${e.message}',
      );
      return false;
    }
  }

  String _getBiometricTypeString(List<BiometricType> biometrics) {
    if (biometrics.contains(BiometricType.face)) {
      return 'face';
    } else if (biometrics.contains(BiometricType.fingerprint)) {
      return 'fingerprint';
    } else if (biometrics.contains(BiometricType.iris)) {
      return 'iris';
    } else if (biometrics.contains(BiometricType.strong)) {
      return 'strong';
    } else if (biometrics.contains(BiometricType.weak)) {
      return 'weak';
    } else {
      return 'unknown';
    }
  }

  Future<bool> requiresBiometricAuth(String operation) async {
    if (!_sensitiveOperations.contains(operation)) {
      return false;
    }

    final isBiometricEnabled = await _secureStorage.getBiometricEnabled();
    final isAvailable = await isBiometricAvailable();
    return isBiometricEnabled && isAvailable;
  }

  Future<T?> performSecureOperation<T>(
    String operation,
    Future<T?> Function() action,
  ) async {
    if (await requiresBiometricAuth(operation)) {
      final authenticated = await authenticateWithBiometrics();
      if (!authenticated) {
        throw PlatformException(
          code: 'auth_required',
          message: 'Biometric authentication is required for this operation',
        );
      }
    }
    return await action();
  }
}
