import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/upi_details.dart';
import '../models/transaction.dart';
import 'api_service.dart';
import 'database_service.dart';

class UPIService {
  static const _storage = FlutterSecureStorage();
  static const _upiKey = 'user_upi_accounts';
  static const _uuid = Uuid();
  final _apiService = APIService();
  final _databaseService = DatabaseService();

  Future<List<UPIDetails>> getUPIAccounts() async {
    try {
      final upiJson = await _storage.read(key: _upiKey);
      if (upiJson == null) return [];

      final List<dynamic> upiList = jsonDecode(upiJson);
      return upiList
          .map((upi) => UPIDetails.fromJson(upi as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> addUPIAccount(UPIDetails upiDetails) async {
    try {
      // Verify UPI ID with the server
      final isValid = await _apiService.verifyUPIId(upiDetails.upiId);
      if (!isValid) {
        throw Exception('Invalid UPI ID');
      }

      final accounts = await getUPIAccounts();
      if (upiDetails.isDefault) {
        for (var i = 0; i < accounts.length; i++) {
          if (accounts[i].isDefault) {
            accounts[i] = accounts[i].copyWith(isDefault: false);
          }
        }
      }
      accounts.add(upiDetails);
      await _saveUPIAccounts(accounts);
    } catch (e) {
      throw Exception('Failed to add UPI account');
    }
  }

  Future<void> removeUPIAccount(String upiId) async {
    try {
      final accounts = await getUPIAccounts();
      accounts.removeWhere((account) => account.id == upiId);
      await _saveUPIAccounts(accounts);
    } catch (e) {
      throw Exception('Failed to remove UPI account');
    }
  }

  Future<void> setDefaultUPIAccount(String upiId) async {
    try {
      final accounts = await getUPIAccounts();
      final updatedAccounts = accounts.map((account) {
        return account.copyWith(
          isDefault: account.id == upiId,
        );
      }).toList();
      await _saveUPIAccounts(updatedAccounts);
    } catch (e) {
      throw Exception('Failed to set default UPI account');
    }
  }

  Future<void> _saveUPIAccounts(List<UPIDetails> accounts) async {
    try {
      final upiJson = jsonEncode(accounts.map((upi) => upi.toJson()).toList());
      await _storage.write(key: _upiKey, value: upiJson);
    } catch (e) {
      throw Exception('Failed to save UPI accounts');
    }
  }

  String generateUPIId() {
    return _uuid.v4();
  }

  Future<bool> initiateUPIPayment({
    required String upiId,
    required double amount,
    required String note,
    String? merchantId,
  }) async {
    try {
      // First, initiate the payment on the server
      final response = await _apiService.initiatePayment(
        upiId: upiId,
        amount: amount,
        note: note,
      );

      final transactionId = response['transactionId'] as String;

      // Create the UPI URI
      final uri = Uri(
        scheme: 'upi',
        path: 'pay',
        queryParameters: {
          'pa': upiId,
          'pn': 'Green Pay',
          'tn': note,
          'am': amount.toString(),
          'cu': 'INR',
          'tr': transactionId,
          if (merchantId != null) 'mid': merchantId,
        },
      );

      final canLaunch = await canLaunchUrl(uri);
      if (!canLaunch) {
        throw Exception('No UPI app found');
      }

      // Launch the UPI app
      final launched = await launchUrl(uri);
      if (!launched) {
        throw Exception('Failed to launch UPI app');
      }

      // Add the transaction to the database
      await _databaseService.addTransaction(
        Transaction(
          id: transactionId,
          title: note,
          amount: amount,
          timestamp: DateTime.now(),
          type: TransactionType.debit,
          category: TransactionCategory.others,
          upiId: upiId,
        ),
      );

      // Verify the payment status
      await _verifyPayment(transactionId);

      return true;
    } catch (e) {
      throw Exception('Failed to initiate UPI payment');
    }
  }

  Future<void> _verifyPayment(String transactionId) async {
    try {
      final response = await _apiService.verifyPayment(transactionId);
      final status = response['status'] as String;

      if (status != 'SUCCESS') {
        throw Exception('Payment failed: $status');
      }
    } catch (e) {
      throw Exception('Failed to verify payment');
    }
  }

  Future<bool> verifyUPIId(String upiId) async {
    try {
      return await _apiService.verifyUPIId(upiId);
    } catch (e) {
      return false;
    }
  }

  Future<void> clearUPIAccounts() async {
    try {
      await _storage.delete(key: _upiKey);
    } catch (e) {
      throw Exception('Failed to clear UPI accounts');
    }
  }
}
