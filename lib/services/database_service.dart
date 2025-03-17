import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/transaction.dart';
import 'api_service.dart';

class DatabaseService {
  static const _storage = FlutterSecureStorage();

  static const _transactionsKey = 'transactions';
  static const _lastSyncKey = 'last_sync_timestamp';
  final _apiService = APIService();

  // Singleton instance
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Future<List<Transaction>> getTransactions() async {
    try {
      // Try to sync with server first
      await _syncTransactions();

      // Return cached transactions
      final transactionsJson = await _storage.read(key: _transactionsKey);
      if (transactionsJson == null) return [];

      final List<dynamic> transactionsList = jsonDecode(transactionsJson);
      return transactionsList
          .map((tx) => Transaction.fromJson(tx as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    } catch (e) {
      // If sync fails, return cached data
      return _getCachedTransactions();
    }
  }

  Future<List<Transaction>> _getCachedTransactions() async {
    try {
      final transactionsJson = await _storage.read(key: _transactionsKey);
      if (transactionsJson == null) return [];

      final List<dynamic> transactionsList = jsonDecode(transactionsJson);
      return transactionsList
          .map((tx) => Transaction.fromJson(tx as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    } catch (e) {
      return [];
    }
  }

  Future<void> _syncTransactions() async {
    try {
      final lastSync = await _storage.read(key: _lastSyncKey);
      final response = await _apiService.get(
        '${APIEndpoints.transactions}?since=${lastSync ?? '0'}',
      );

      final List<dynamic> serverTransactions = response['transactions'];
      final transactions = serverTransactions
          .map((tx) => Transaction.fromJson(tx as Map<String, dynamic>))
          .toList();

      // Merge with local transactions
      final localTransactions = await _getCachedTransactions();
      final mergedTransactions =
          _mergeTransactions(localTransactions, transactions);

      // Save merged transactions
      await _saveTransactions(mergedTransactions);
      await _storage.write(
        key: _lastSyncKey,
        value: DateTime.now().toIso8601String(),
      );
    } catch (e) {
      // If sync fails, continue with cached data
      rethrow;
    }
  }

  List<Transaction> _mergeTransactions(
    List<Transaction> local,
    List<Transaction> server,
  ) {
    final merged = <Transaction>[];
    final seen = <String>{};

    // Add server transactions first (they take precedence)
    for (final tx in server) {
      merged.add(tx);
      seen.add(tx.id);
    }

    // Add local transactions that aren't on the server
    for (final tx in local) {
      if (!seen.contains(tx.id)) {
        merged.add(tx);
      }
    }

    return merged..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  Future<void> addTransaction(Transaction transaction) async {
    try {
      // Send to server first
      await _apiService.post(
        APIEndpoints.transactions,
        transaction.toJson(),
      );

      // If successful, add to local cache
      final transactions = await _getCachedTransactions();
      transactions.insert(0, transaction);
      await _saveTransactions(transactions);
    } catch (e) {
      // If server is unavailable, save locally and sync later
      final transactions = await _getCachedTransactions();
      transactions.insert(0, transaction);
      await _saveTransactions(transactions);
      throw Exception('Transaction saved locally. Will sync when online.');
    }
  }

  Future<void> _saveTransactions(List<Transaction> transactions) async {
    try {
      final transactionsJson =
          jsonEncode(transactions.map((tx) => tx.toJson()).toList());
      await _storage.write(key: _transactionsKey, value: transactionsJson);
    } catch (e) {
      throw Exception('Failed to save transactions');
    }
  }

  Future<void> clearTransactions() async {
    try {
      await _storage.delete(key: _transactionsKey);
      await _storage.delete(key: _lastSyncKey);
    } catch (e) {
      throw Exception('Failed to clear transactions');
    }
  }

  Future<Map<String, double>> getMonthlySpending() async {
    try {
      final response = await _apiService
          .get('${APIEndpoints.transactions}/monthly-spending');
      return Map<String, double>.from(response['spending']);
    } catch (e) {
      // If API fails, calculate from cached data
      final transactions = await _getCachedTransactions();
      final Map<String, double> monthlySpending = {};

      for (var transaction in transactions) {
        if (transaction.type == TransactionType.debit) {
          final key =
              '${transaction.timestamp.year}-${transaction.timestamp.month}';
          monthlySpending[key] =
              (monthlySpending[key] ?? 0) + transaction.amount;
        }
      }

      return monthlySpending;
    }
  }

  Future<double> getTotalBalance() async {
    try {
      final response =
          await _apiService.get('${APIEndpoints.transactions}/balance');
      return response['balance'] as double;
    } catch (e) {
      // If API fails, calculate from cached data
      final transactions = await _getCachedTransactions();
      return transactions.fold<double>(0.0, (total, tx) {
        return total +
            (tx.type == TransactionType.credit ? tx.amount : -tx.amount);
      });
    }
  }
}
