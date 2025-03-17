import 'package:green_pay/models/budget.dart';
import 'package:green_pay/services/api_service.dart';
import 'package:green_pay/models/transaction.dart';

class BudgetService {
  final ApiService _apiService;

  BudgetService(this._apiService);

  Future<List<Budget>> getBudgets() async {
    final response = await _apiService.get('/budgets');
    return (response['data'] as List)
        .map((json) => Budget.fromJson(json))
        .toList();
  }

  Future<Budget> createBudget(Budget budget) async {
    final response = await _apiService.post('/budgets', budget.toJson());
    return Budget.fromJson(response['data']);
  }

  Future<Budget> updateBudget(Budget budget) async {
    final response =
        await _apiService.put('/budgets/${budget.id}', budget.toJson());
    return Budget.fromJson(response['data']);
  }

  Future<void> deleteBudget(String budgetId) async {
    await _apiService.delete('/budgets/$budgetId');
  }

  Future<Map<String, dynamic>> getSpendingAnalytics({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final response = await _apiService.get(
      '/analytics/spending',
      queryParameters: {
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
      },
    );
    return response['data'];
  }

  Future<void> updateBudgetSpending(
      String budgetId, Transaction transaction) async {
    if (transaction.type == TransactionType.debit) {
      await _apiService.post(
        '/budgets/$budgetId/transactions',
        {'transactionId': transaction.id},
      );
    }
  }

  Future<List<Map<String, dynamic>>> getCategoryWiseSpending({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final response = await _apiService.get(
      '/analytics/categories',
      queryParameters: {
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
      },
    );
    return List<Map<String, dynamic>>.from(response['data']);
  }

  Future<Map<String, dynamic>> getBudgetSummary(String budgetId) async {
    final response = await _apiService.get('/budgets/$budgetId/summary');
    return response['data'];
  }
}
