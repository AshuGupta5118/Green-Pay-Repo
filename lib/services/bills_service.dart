import 'dart:convert';
import 'package:green_pay/models/bill.dart';
import 'package:green_pay/models/bill_provider.dart';
import 'package:green_pay/services/api_service.dart';

class BillsService {
  final APIService _apiService = APIService();

  // Singleton instance
  static final BillsService _instance = BillsService._internal();
  factory BillsService() => _instance;
  BillsService._internal();

  Future<List<String>> getBillCategories() async {
    try {
      final response = await _apiService.get('/bills/categories');
      return List<String>.from(response['categories']);
    } catch (e) {
      throw Exception('Failed to load bill categories: $e');
    }
  }

  Future<List<BillProvider>> getBillProviders(String category) async {
    try {
      final response =
          await _apiService.get('/bills/providers?category=$category');
      return (response['providers'] as List)
          .map((json) => BillProvider.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to load bill providers: $e');
    }
  }

  Future<Bill> fetchBillDetails({
    required String providerId,
    required String customerNumber,
    String? consumerNumber,
  }) async {
    try {
      final response = await _apiService.post('/bills/fetch', {
        'providerId': providerId,
        'customerNumber': customerNumber,
        if (consumerNumber != null) 'consumerNumber': consumerNumber,
      });

      if (response['success'] == true) {
        return Bill.fromJson(response['bill']);
      } else {
        throw Exception(response['message'] ?? 'Failed to fetch bill details');
      }
    } catch (e) {
      throw Exception('Failed to fetch bill details: $e');
    }
  }

  Future<Bill> payBill({
    required String billId,
    required double amount,
    required String mobileNumber,
    String? emailId,
  }) async {
    try {
      final response = await _apiService.post('/bills/pay', {
        'billId': billId,
        'amount': amount,
        'mobileNumber': mobileNumber,
        if (emailId != null) 'emailId': emailId,
      });

      if (response['success'] == true) {
        return Bill.fromJson(response['bill']);
      } else {
        throw Exception(response['message'] ?? 'Failed to pay bill');
      }
    } catch (e) {
      throw Exception('Failed to pay bill: $e');
    }
  }

  Future<List<Bill>> getBillHistory() async {
    try {
      final response = await _apiService.get('/bills/history');
      return (response['bills'] as List)
          .map((json) => Bill.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to load bill history: $e');
    }
  }

  Future<Bill> getBillStatus(String billId) async {
    try {
      final response = await _apiService.get('/bills/status/$billId');
      return Bill.fromJson(response['bill']);
    } catch (e) {
      throw Exception('Failed to get bill status: $e');
    }
  }
}
