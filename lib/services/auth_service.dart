import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import '../models/user.dart';
import 'api_service.dart';
import '../utils/secure_storage.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/error_codes.dart' as auth_error;

class AuthService {
  static const _storage = FlutterSecureStorage();

  static const _userKey = 'user_data';

  final _secureStorage = SecureStorage();
  final _localAuth = LocalAuthentication();
  final _apiService = APIService();

  // Singleton instance
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  User? _currentUser;
  bool get isAuthenticated => _currentUser != null;

  static const String _biometricEnabledKey = 'biometric_enabled';

  Future<void> initialize() async {
    try {
      final userJson = await _storage.read(key: _userKey);
      if (userJson != null) {
        _currentUser = User.fromJson(jsonDecode(userJson));
        // Verify token validity by fetching profile
        try {
          final profile = await _apiService.getProfile();
          _currentUser = profile;
          await _storage.write(
              key: _userKey, value: jsonEncode(profile.toJson()));
        } catch (e) {
          // Token is invalid, clear user data
          await logout();
        }
      }
    } catch (e) {
      _currentUser = null;
      await _storage.delete(key: _userKey);
    }
  }

  Future<bool> login(String phone, String otp) async {
    try {
      final success = await _apiService.verifyOTP(phone, otp);
      if (success) {
        final profile = await _apiService.getProfile();
        _currentUser = profile;
        await _storage.write(
            key: _userKey, value: jsonEncode(profile.toJson()));
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> verifyPhone(String phone) async {
    try {
      final response = await _apiService.post(
        '${APIEndpoints.auth}/send-otp',
        {'phone': phone},
        requiresAuth: false,
      );
      return response['success'] as bool;
    } catch (e) {
      return false;
    }
  }

  Future<bool> logout() async {
    try {
      await _apiService.post('${APIEndpoints.auth}/logout', {});
      _currentUser = null;
      await _storage.delete(key: _userKey);
      await _secureStorage.deleteAuthToken();
      await _secureStorage.deleteRefreshToken();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> authenticateWithBiometrics() async {
    try {
      return await _localAuth.authenticate(
        localizedReason: 'Authenticate to access the app',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } on PlatformException catch (e) {
      if (e.code == auth_error.notAvailable ||
          e.code == auth_error.notEnrolled ||
          e.code == auth_error.passcodeNotSet) {
        return false;
      }
      rethrow;
    }
  }

  Future<bool> updateProfile({String? name, String? email}) async {
    try {
      if (_currentUser == null) return false;

      final updatedUser = await _apiService.updateProfile({
        if (name != null) 'name': name,
        if (email != null) 'email': email,
      });

      _currentUser = updatedUser;
      await _storage.write(
          key: _userKey, value: jsonEncode(updatedUser.toJson()));
      return true;
    } catch (e) {
      return false;
    }
  }

  User? get currentUser => _currentUser;

  Future<bool> loginWithPhone(String phoneNumber) async {
    try {
      final response = await _apiService.post(
        '${APIEndpoints.auth}/send-otp',
        {'phone': phoneNumber},
        requiresAuth: false,
      );
      return response['success'] as bool;
    } catch (e) {
      return false;
    }
  }

  Future<User?> verifyOtp(String phoneNumber, String otp) async {
    try {
      final response = await _apiService.post(
        '${APIEndpoints.auth}/verify-otp',
        {'phone': phoneNumber, 'otp': otp},
        requiresAuth: false,
      );

      if (response['success'] as bool) {
        final userData = response['data']['user'];
        final token = response['data']['token'] as String;
        final refreshToken = response['data']['refreshToken'] as String;

        final user = User.fromJson(userData);

        // Store user data and tokens
        await _storeUserData(user);
        await _secureStorage.setAuthToken(token);
        await _secureStorage.setRefreshToken(refreshToken);

        return user;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<User?> getCurrentUser() async {
    final userData = await _storage.read(key: _userKey);
    if (userData == null) return null;

    try {
      return User.fromJson(json.decode(userData));
    } catch (e) {
      return null;
    }
  }

  Future<bool> isLoggedIn() async {
    final token = await _secureStorage.getAuthToken();
    return token != null;
  }

  Future<void> _storeUserData(User user) async {
    await _storage.write(key: _userKey, value: json.encode(user.toJson()));
  }

  Future<String?> getToken() async {
    return await _secureStorage.getAuthToken();
  }

  Future<String?> getRefreshToken() async {
    return await _secureStorage.getRefreshToken();
  }

  Future<void> updateTokens(
      {required String token, required String refreshToken}) async {
    await _secureStorage.setAuthToken(token);
    await _secureStorage.setRefreshToken(refreshToken);
  }

  Future<bool> isBiometricAvailable() async {
    try {
      final isAvailable = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      return isAvailable && isDeviceSupported;
    } on PlatformException catch (_) {
      return false;
    }
  }

  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } on PlatformException catch (_) {
      return [];
    }
  }

  Future<bool> isBiometricEnabled() async {
    try {
      return await _secureStorage.getBiometricEnabled();
    } catch (_) {
      return false;
    }
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    try {
      await _secureStorage.setBiometricEnabled(enabled);
    } catch (_) {
      // Handle error
      rethrow;
    }
  }
}
