import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  ApiException(this.message, {this.statusCode, this.data});

  @override
  String toString() => 'ApiException: $message (Status: $statusCode)';
}

class ApiClient {
  static const String baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://localhost:3000/api',
  );

  final storage = const FlutterSecureStorage();
  final http.Client _client = http.Client();

  // Headers
  Future<Map<String, String>> _getHeaders({bool requiresAuth = true}) async {
    Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (requiresAuth) {
      final token = await storage.read(key: 'auth_token');
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      } else {
        throw ApiException('Authentication token not found');
      }
    }

    return headers;
  }

  Future<T> _handleResponse<T>(
      http.Response response, T Function(Map<String, dynamic>) parser) async {
    try {
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return parser(data);
      } else {
        Map<String, dynamic>? errorData;
        try {
          errorData = jsonDecode(response.body);
        } catch (_) {
          errorData = null;
        }

        throw ApiException(
          errorData?['message'] ?? 'Request failed',
          statusCode: response.statusCode,
          data: errorData,
        );
      }
    } on FormatException {
      throw ApiException('Invalid response format');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Unexpected error: ${e.toString()}');
    }
  }

  // Authentication endpoints
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: await _getHeaders(requiresAuth: false),
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    final result = await _handleResponse(response, (data) => data);
    await storage.write(key: 'auth_token', value: result['token']);
    return result;
  }

  Future<Map<String, dynamic>> register(
      String name, String email, String password) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: await _getHeaders(requiresAuth: false),
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
      }),
    );

    return _handleResponse(response, (data) => data);
  }

  // Payment endpoints
  Future<Map<String, dynamic>> initiatePayment(
      Map<String, dynamic> paymentDetails) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/payments/initiate'),
      headers: await _getHeaders(),
      body: jsonEncode(paymentDetails),
    );

    return _handleResponse(response, (data) => data);
  }

  Future<Map<String, dynamic>> processPayment(String paymentId) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/payments/process/$paymentId'),
      headers: await _getHeaders(),
    );

    return _handleResponse(response, (data) => data);
  }

  Future<List<Map<String, dynamic>>> getPaymentHistory() async {
    final response = await _client.get(
      Uri.parse('$baseUrl/payments/history'),
      headers: await _getHeaders(),
    );

    return _handleResponse(response, (data) {
      final List<dynamic> list = data['payments'] ?? data;
      return list.cast<Map<String, dynamic>>();
    });
  }

  // UPI endpoints
  Future<String> generateUPIDeepLink(Map<String, dynamic> upiDetails) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/upi/generate-link'),
      headers: await _getHeaders(),
      body: jsonEncode(upiDetails),
    );

    return _handleResponse(response, (data) => data['deepLink'] as String);
  }

  Future<Map<String, dynamic>> verifyUPITransaction(
      String transactionId) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/upi/verify/$transactionId'),
      headers: await _getHeaders(),
    );

    return _handleResponse(response, (data) => data);
  }

  // User profile endpoints
  Future<Map<String, dynamic>> getUserProfile() async {
    final response = await _client.get(
      Uri.parse('$baseUrl/users/profile'),
      headers: await _getHeaders(),
    );

    return _handleResponse(response, (data) => data);
  }

  Future<Map<String, dynamic>> updateUserProfile(
      Map<String, dynamic> profileData) async {
    final response = await _client.put(
      Uri.parse('$baseUrl/users/profile'),
      headers: await _getHeaders(),
      body: jsonEncode(profileData),
    );

    return _handleResponse(response, (data) => data);
  }

  // Error handling helper
  void handleError(dynamic error) {
    if (error is ApiException) {
      print('API Error: ${error.message} (Status: ${error.statusCode})');
      if (error.data != null) {
        print('Error details: ${error.data}');
      }
    } else {
      print('Unexpected error: $error');
    }
    throw error;
  }

  // Cleanup
  void dispose() {
    _client.close();
  }
}
