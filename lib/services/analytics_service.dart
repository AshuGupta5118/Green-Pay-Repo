import 'package:flutter/foundation.dart';

/// A service for tracking analytics events in the app.
///
/// This is a placeholder implementation that can be replaced with
/// a real analytics provider like Firebase Analytics, Mixpanel, etc.
class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  // Biometric authentication events
  static const String biometricAuthSuccess = 'biometric_auth_success';
  static const String biometricAuthFailure = 'biometric_auth_failure';
  static const String biometricAuthCancelled = 'biometric_auth_cancelled';
  static const String biometricAuthEnabled = 'biometric_auth_enabled';
  static const String biometricAuthDisabled = 'biometric_auth_disabled';
  static const String biometricAuthNotAvailable =
      'biometric_auth_not_available';

  // Security events
  static const String secureStorageAccessed = 'secure_storage_accessed';
  static const String secureStorageKeyRotated = 'secure_storage_key_rotated';
  static const String secureStorageCleared = 'secure_storage_cleared';

  /// Log an event with optional parameters
  Future<void> logEvent(String eventName,
      {Map<String, dynamic>? parameters}) async {
    if (kDebugMode) {
      print(
          'Analytics Event: $eventName ${parameters != null ? '- $parameters' : ''}');
    }

    // TODO: Implement real analytics tracking
    // Example with Firebase Analytics:
    // await FirebaseAnalytics.instance.logEvent(
    //   name: eventName,
    //   parameters: parameters,
    // );
  }

  /// Track biometric authentication success
  Future<void> trackBiometricAuthSuccess(String biometricType) async {
    await logEvent(biometricAuthSuccess, parameters: {
      'biometric_type': biometricType,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Track biometric authentication failure
  Future<void> trackBiometricAuthFailure(
      String biometricType, String reason) async {
    await logEvent(biometricAuthFailure, parameters: {
      'biometric_type': biometricType,
      'reason': reason,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Track biometric authentication cancelled by user
  Future<void> trackBiometricAuthCancelled(String biometricType) async {
    await logEvent(biometricAuthCancelled, parameters: {
      'biometric_type': biometricType,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Track biometric authentication enabled
  Future<void> trackBiometricAuthEnabled(String biometricType) async {
    await logEvent(biometricAuthEnabled, parameters: {
      'biometric_type': biometricType,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Track biometric authentication disabled
  Future<void> trackBiometricAuthDisabled(String biometricType) async {
    await logEvent(biometricAuthDisabled, parameters: {
      'biometric_type': biometricType,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Track secure storage access
  Future<void> trackSecureStorageAccess(String key, String operation) async {
    await logEvent(secureStorageAccessed, parameters: {
      'key': key,
      'operation': operation,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Track secure storage key rotation
  Future<void> trackSecureStorageKeyRotation() async {
    await logEvent(secureStorageKeyRotated, parameters: {
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
}
