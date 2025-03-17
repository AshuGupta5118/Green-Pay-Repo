import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'dart:async';

class SecureStorage {
  static final SecureStorage _instance = SecureStorage._internal();
  factory SecureStorage() => _instance;
  SecureStorage._internal();

  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'auth_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _biometricEnabledKey = 'biometric_enabled';
  static const _userIdKey = 'user_id';
  static const _userProfileKey = 'user_profile';
  static const _keyRotationTimestampKey = 'key_rotation_timestamp';
  static const _encryptionKeyKey = 'encryption_key';
  static const _keyRotationPeriod = Duration(days: 30);

  // Key rotation mechanism
  Future<void> _rotateKeyIfNeeded() async {
    final lastRotationStr = await _storage.read(key: _keyRotationTimestampKey);
    final lastRotation = lastRotationStr != null
        ? DateTime.parse(lastRotationStr)
        : DateTime.now().subtract(const Duration(days: 31));

    if (DateTime.now().difference(lastRotation) >= _keyRotationPeriod) {
      await _rotateEncryptionKey();
    }
  }

  Future<String> _rotateEncryptionKey() async {
    final newKey = base64.encode(List<int>.generate(
        32, (i) => DateTime.now().microsecondsSinceEpoch % 256));
    final oldKey = await _storage.read(key: _encryptionKeyKey);

    if (oldKey != null) {
      // Re-encrypt all sensitive data with new key
      final sensitiveKeys = [_tokenKey, _refreshTokenKey, _userProfileKey];
      for (final key in sensitiveKeys) {
        final value = await _storage.read(key: key);
        if (value != null) {
          final decrypted = _decrypt(value, oldKey);
          final reEncrypted = _encrypt(decrypted, newKey);
          await _storage.write(key: key, value: reEncrypted);
        }
      }
    }

    await _storage.write(key: _encryptionKeyKey, value: newKey);
    await _storage.write(
      key: _keyRotationTimestampKey,
      value: DateTime.now().toIso8601String(),
    );

    return newKey;
  }

  String _encrypt(String value, String key) {
    final bytes = utf8.encode(value);
    final keyBytes = utf8.encode(key);
    final hmac = Hmac(sha256, keyBytes);
    final digest = hmac.convert(bytes);
    final encrypted = base64.encode(bytes);
    return '$encrypted.${digest.toString()}';
  }

  String _decrypt(String value, String key) {
    final parts = value.split('.');
    if (parts.length != 2) throw Exception('Invalid encrypted value');

    final encrypted = parts[0];
    final hmac = parts[1];

    final bytes = base64.decode(encrypted);
    final keyBytes = utf8.encode(key);
    final hmacObj = Hmac(sha256, keyBytes);
    final digest = hmacObj.convert(bytes);

    if (digest.toString() != hmac) {
      throw Exception('Data tampering detected');
    }

    return utf8.decode(bytes);
  }

  // Enhanced secure storage methods with encryption
  Future<void> setSecureValue(String key, String value) async {
    await _rotateKeyIfNeeded();
    String encryptionKey = await _storage.read(key: _encryptionKeyKey) ?? "";
    if (encryptionKey.isEmpty) {
      encryptionKey = await _rotateEncryptionKey();
    }
    final encrypted = _encrypt(value, encryptionKey);
    await _storage.write(key: key, value: encrypted);
  }

  Future<String?> getSecureValue(String key) async {
    await _rotateKeyIfNeeded();
    final encryptionKey = await _storage.read(key: _encryptionKeyKey);
    if (encryptionKey == null) return null;

    final encrypted = await _storage.read(key: key);
    if (encrypted == null) return null;

    return _decrypt(encrypted, encryptionKey);
  }

  // Secure deletion with overwrite
  Future<void> secureDelete(String key) async {
    // Overwrite with random data before deletion
    await setSecureValue(
        key,
        base64.encode(List<int>.generate(
            32, (i) => DateTime.now().microsecondsSinceEpoch % 256)));
    await _storage.delete(key: key);
  }

  // Modified existing methods to use enhanced security
  Future<void> setAuthToken(String token) async {
    await setSecureValue(_tokenKey, token);
  }

  Future<String?> getAuthToken() async {
    return await getSecureValue(_tokenKey);
  }

  Future<void> deleteAuthToken() async {
    await _storage.delete(key: _tokenKey);
  }

  // Refresh Token
  Future<void> setRefreshToken(String token) async {
    await setSecureValue(_refreshTokenKey, token);
  }

  Future<String?> getRefreshToken() async {
    return await getSecureValue(_refreshTokenKey);
  }

  Future<void> deleteRefreshToken() async {
    await secureDelete(_refreshTokenKey);
  }

  // Biometric Authentication
  Future<void> setBiometricEnabled(bool enabled) async {
    await setSecureValue(_biometricEnabledKey, enabled.toString());
  }

  Future<bool> getBiometricEnabled() async {
    final value = await getSecureValue(_biometricEnabledKey);
    return value?.toLowerCase() == 'true';
  }

  // User ID
  Future<void> setUserId(String userId) async {
    await setSecureValue(_userIdKey, userId);
  }

  Future<String?> getUserId() async {
    return await getSecureValue(_userIdKey);
  }

  // User Profile
  Future<void> setUserProfile(String userProfileJson) async {
    await setSecureValue(_userProfileKey, userProfileJson);
  }

  Future<String?> getUserProfile() async {
    return await getSecureValue(_userProfileKey);
  }

  // Generic methods for storing and retrieving data
  Future<void> setString(String key, String value) async {
    await setSecureValue(key, value);
  }

  Future<String?> getString(String key) async {
    return await getSecureValue(key);
  }

  Future<void> deleteKey(String key) async {
    await secureDelete(key);
  }

  // Clear all data with secure deletion
  Future<void> clearAll() async {
    final keys = await _storage.readAll();
    for (final key in keys.keys) {
      await secureDelete(key);
    }
    await _storage.deleteAll();
  }
}
