import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class EnvConfig {
  static const String _prodBaseUrl = 'https://api.greenpay.com';
  static const String _stagingBaseUrl = 'https://staging-api.greenpay.com';
  static const String _devBaseUrl = 'https://dev-api.greenpay.com';

  static const String _apiKeyKey = 'API_KEY';
  static const String _merchantIdKey = 'MERCHANT_ID';
  static const String _encryptionKeyKey = 'ENCRYPTION_KEY';

  static late final FlutterSecureStorage _secureStorage;
  static bool _isInitialized = false;

  static Future<void> initialize({
    required String apiKey,
    required String merchantId,
    required String encryptionKey,
    bool isProduction = false,
    bool isStaging = false,
  }) async {
    if (_isInitialized) return;

    _secureStorage = const FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
      iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
    );

    // Store sensitive data securely
    await _secureStorage.write(key: _apiKeyKey, value: apiKey);
    await _secureStorage.write(key: _merchantIdKey, value: merchantId);
    await _secureStorage.write(key: _encryptionKeyKey, value: encryptionKey);

    _isInitialized = true;
  }

  static String get baseUrl {
    assert(_isInitialized, 'EnvConfig must be initialized before use');
    if (const bool.fromEnvironment('dart.vm.product')) {
      return _prodBaseUrl;
    } else if (const bool.fromEnvironment('STAGING')) {
      return _stagingBaseUrl;
    }
    return _devBaseUrl;
  }

  static Future<String> get apiKey async {
    assert(_isInitialized, 'EnvConfig must be initialized before use');
    return await _secureStorage.read(key: _apiKeyKey) ?? '';
  }

  static Future<String> get merchantId async {
    assert(_isInitialized, 'EnvConfig must be initialized before use');
    return await _secureStorage.read(key: _merchantIdKey) ?? '';
  }

  static Future<String> get encryptionKey async {
    assert(_isInitialized, 'EnvConfig must be initialized before use');
    return await _secureStorage.read(key: _encryptionKeyKey) ?? '';
  }

  // API Endpoints
  static String get authEndpoint => '$baseUrl/v1/auth';
  static String get transactionsEndpoint => '$baseUrl/v1/transactions';
  static String get paymentsEndpoint => '$baseUrl/v1/payments';
  static String get upiEndpoint => '$baseUrl/v1/upi';
  static String get cardsEndpoint => '$baseUrl/v1/cards';
  static String get profileEndpoint => '$baseUrl/v1/profile';
  static String get notificationsEndpoint => '$baseUrl/v1/notifications';

  // Webhook URLs
  static String get paymentWebhookUrl => '$baseUrl/webhooks/payment';
  static String get upiCallbackUrl => '$baseUrl/webhooks/upi-callback';
}
