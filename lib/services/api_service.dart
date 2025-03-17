import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user.dart';
import 'auth_service.dart';
import '../utils/secure_storage.dart';

class APIEndpoints {
  static const String baseUrl =
      'https://api.greenpay.com'; // Replace with your actual API URL
  static const String auth = '/auth';
  static const String verifyOtp = '$auth/verify-otp';
  static const String refreshToken = '$auth/refresh-token';
  static const String profile = '/profile';
  static const String transactions = '/transactions';
  static const String payments = '/payments';
  static const String upi = '/upi';
  static const String cards = '/cards';
  static const String wallet = '/wallet';
  static const String walletTopup = '$payments/wallet/topup';
  static const String walletConfirm = '$payments/wallet/confirm';
  static const String walletHistory = '$payments/wallet/history';
}

class APIError implements Exception {
  final String message;
  final int? statusCode;
  final Map<String, dynamic>? data;

  APIError(this.message, {this.statusCode, this.data});

  @override
  String toString() => 'APIError: $message (Status: $statusCode)';
}

class ApiService {
  final String baseUrl;
  final FlutterSecureStorage _storage;
  final http.Client _client;
  final _secureStorage = SecureStorage();

  ApiService({
    required this.baseUrl,
    FlutterSecureStorage? storage,
    http.Client? client,
  })  : _storage = storage ?? const FlutterSecureStorage(),
        _client = client ?? http.Client();

  Future<String?> get _token async => await _secureStorage.getAuthToken();

  Future<Map<String, String>> get _headers async {
    final token = await _token;
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<Map<String, dynamic>> _handleResponse(http.Response response) async {
    final body = json.decode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    throw ApiException(
      statusCode: response.statusCode,
      message: body['message'] ?? 'Unknown error occurred',
    );
  }

  Future<Map<String, dynamic>> get(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
  }) async {
    final uri = Uri.parse('$baseUrl$endpoint').replace(
      queryParameters: queryParameters?.map(
        (key, value) => MapEntry(key, value.toString()),
      ),
    );

    final response = await _client.get(
      uri,
      headers: await _headers,
    );

    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final response = await _client.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: await _headers,
      body: json.encode(body),
    );

    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> put(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final response = await _client.put(
      Uri.parse('$baseUrl$endpoint'),
      headers: await _headers,
      body: json.encode(body),
    );

    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> delete(String endpoint) async {
    final response = await _client.delete(
      Uri.parse('$baseUrl$endpoint'),
      headers: await _headers,
    );

    return _handleResponse(response);
  }

  void dispose() {
    _client.close();
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException({
    required this.statusCode,
    required this.message,
  });

  @override
  String toString() => 'ApiException: $statusCode - $message';
}

class APIService {
  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'auth_token';
  static const _refreshTokenKey = 'refresh_token';

  final ApiService _apiService;
  final AuthService _authService;
  final _secureStorage = SecureStorage();
  bool _isRefreshing = false;

  // Singleton instance
  static final APIService _instance = APIService._internal();
  factory APIService() => _instance;

  APIService._internal()
      : _apiService = ApiService(baseUrl: APIEndpoints.baseUrl),
        _authService = AuthService();

  // Handle authentication for requests
  Future<Map<String, dynamic>> _authenticatedRequest(
    Future<Map<String, dynamic>> Function() requestFunc,
  ) async {
    try {
      return await requestFunc();
    } on ApiException catch (e) {
      if (e.statusCode == 401 && !_isRefreshing) {
        _isRefreshing = true;
        try {
          final newToken = await _refreshAuthToken();
          if (newToken != null) {
            // Retry the request with the new token
            _isRefreshing = false;
            return await requestFunc();
          }
        } catch (refreshError) {
          _isRefreshing = false;
          await _handleAuthError();
          rethrow;
        }
      }
      rethrow;
    }
  }

  Future<String?> _refreshAuthToken() async {
    try {
      final refreshToken = await _secureStorage.getRefreshToken();
      if (refreshToken == null) throw APIError('No refresh token available');

      final response = await _apiService.post(
        APIEndpoints.refreshToken,
        {'refresh_token': refreshToken},
      );

      if (response['token'] != null) {
        await _secureStorage.setAuthToken(response['token']);
        return response['token'] as String;
      }
      throw APIError('Failed to refresh token');
    } catch (e) {
      return null;
    }
  }

  Future<void> _handleAuthError() async {
    await _secureStorage.deleteAuthToken();
    await _secureStorage.deleteRefreshToken();
    await _authService.logout();
  }

  Future<Map<String, dynamic>> get(String endpoint) async {
    try {
      final response = await _apiService.get(endpoint);
      _validateResponse(response);
      return response;
    } on ApiException catch (e) {
      throw _handleApiError(e);
    }
  }

  Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> data, {
    bool requiresAuth = true,
  }) async {
    try {
      final response = await _apiService.post(
        endpoint,
        data,
      );
      _validateResponse(response);
      return response;
    } on ApiException catch (e) {
      throw _handleApiError(e);
    }
  }

  Future<Map<String, dynamic>> put(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _apiService.put(
        endpoint,
        data,
      );
      _validateResponse(response);
      return response;
    } on ApiException catch (e) {
      throw _handleApiError(e);
    }
  }

  Future<void> delete(String endpoint) async {
    try {
      await _apiService.delete(endpoint);
    } on ApiException catch (e) {
      throw _handleApiError(e);
    }
  }

  void _validateResponse(Map<String, dynamic> response) {
    if (response['message'] != null) {
      throw APIError(
        response['message'],
        statusCode: response['statusCode'],
        data: response,
      );
    }
  }

  APIError _handleApiError(ApiException error) {
    return APIError(
      error.message,
      statusCode: error.statusCode,
    );
  }

  // Auth endpoints
  Future<bool> verifyOTP(String phone, String otp) async {
    try {
      final response = await post(
        APIEndpoints.verifyOtp,
        {'phone': phone, 'otp': otp},
        requiresAuth: false,
      );

      if (response['token'] != null) {
        await _storage.write(key: _tokenKey, value: response['token']);
        if (response['refresh_token'] != null) {
          await _storage.write(
              key: _refreshTokenKey, value: response['refresh_token']);
        }
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Profile endpoints
  Future<User> getProfile() async {
    final response = await get(APIEndpoints.profile);
    return User.fromJson(response);
  }

  Future<User> updateProfile(Map<String, dynamic> data) async {
    final response = await put(APIEndpoints.profile, data);
    return User.fromJson(response);
  }

  // UPI endpoints
  Future<bool> verifyUPIId(String upiId) async {
    try {
      final response =
          await post('${APIEndpoints.upi}/verify', {'upiId': upiId});
      return response['isValid'] as bool;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>> initiatePayment({
    required String upiId,
    required double amount,
    required String note,
  }) async {
    return await post('${APIEndpoints.payments}/initiate', {
      'upiId': upiId,
      'amount': amount,
      'note': note,
    });
  }

  Future<Map<String, dynamic>> verifyPayment(String transactionId) async {
    return await get('${APIEndpoints.payments}/verify/$transactionId');
  }
}
