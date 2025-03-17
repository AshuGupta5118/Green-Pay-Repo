import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/transaction.dart';
import 'api_service.dart';
import 'database_service.dart';

class WalletService {
  final APIService _apiService;
  final DatabaseService _databaseService;

  // Singleton instance
  static final WalletService _instance = WalletService._internal();
  factory WalletService() => _instance;
  WalletService._internal()
      : _apiService = APIService(),
        _databaseService = DatabaseService();

  Future<double> getWalletBalance() async {
    try {
      final response = await _apiService.get('${APIEndpoints.wallet}/balance');
      return response['balance'] as double;
    } catch (e) {
      // If API fails, calculate from cached data
      return _databaseService.getTotalBalance();
    }
  }

  Future<Map<String, dynamic>> addMoneyToWallet({
    required double amount,
    required String method,
    String? gateway,
    String? upiProvider,
  }) async {
    try {
      final response = await _apiService.post(
        APIEndpoints.walletTopup,
        {
          'amount': amount,
          'method': method,
          if (gateway != null) 'gateway': gateway,
          if (upiProvider != null) 'upiProvider': upiProvider,
        },
      );

      return response;
    } catch (e) {
      throw Exception('Failed to add money to wallet: $e');
    }
  }

  Future<bool> confirmWalletTopup({
    required String paymentId,
    required String gatewayPaymentId,
    required String status,
  }) async {
    try {
      final response = await _apiService.post(
        APIEndpoints.walletConfirm,
        {
          'paymentId': paymentId,
          'gatewayPaymentId': gatewayPaymentId,
          'status': status,
        },
      );

      return response['success'] as bool;
    } catch (e) {
      throw Exception('Failed to confirm wallet top-up: $e');
    }
  }

  Future<List<Transaction>> getWalletTransactionHistory({
    int limit = 10,
    int skip = 0,
  }) async {
    try {
      final queryString = '?limit=$limit&skip=$skip';
      final response = await _apiService.get(
        APIEndpoints.walletHistory + queryString,
      );

      final List<dynamic> transactionsJson = response['data'];
      return transactionsJson
          .map((json) => Transaction.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to get wallet transaction history: $e');
    }
  }

  Future<Map<String, dynamic>> getWalletStats() async {
    try {
      final response = await _apiService.get('${APIEndpoints.wallet}/stats');
      return response['data'];
    } catch (e) {
      throw Exception('Failed to get wallet stats: $e');
    }
  }
}
