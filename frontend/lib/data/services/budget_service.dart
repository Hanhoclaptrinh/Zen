import 'package:dio/dio.dart';
import 'package:frontend/data/models/budget_model.dart';
import 'package:frontend/data/services/api_client.dart';

class BudgetService {
  final ApiClient _apiClient;

  BudgetService(this._apiClient);

  Future<List<BudgetModel>> getBudgets() async {
    try {
      final response = await _apiClient.dio.get('/budgets');
      final List<dynamic> data = response.data;
      return data.map((json) => BudgetModel.fromJson(json)).toList();
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to fetch budgets');
    }
  }

  Future<BudgetModel> createBudget(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.dio.post('/budgets', data: data);
      return BudgetModel.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to create budget');
    }
  }

  Future<BudgetModel> updateBudget(int id, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.dio.put('/budgets/$id', data: data);
      return BudgetModel.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to update budget');
    }
  }

  Future<void> deleteBudget(int id) async {
    try {
      await _apiClient.dio.delete('/budgets/$id');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to delete budget');
    }
  }

  Future<Map<String, dynamic>> checkBudgetStatus(int budgetId) async {
    try {
      final response = await _apiClient.dio.get('/budgets/$budgetId/status');
      return response.data;
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Failed to check budget status',
      );
    }
  }
}
