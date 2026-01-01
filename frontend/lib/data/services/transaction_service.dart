import 'package:dio/dio.dart';
import 'package:frontend/data/models/transaction_model.dart';
import 'package:frontend/data/services/api_client.dart';

class TransactionService {
  final ApiClient _apiClient;

  TransactionService(this._apiClient);

  Future<List<TransactionModel>> getTransactions() async {
    try {
      final response = await _apiClient.dio.get('/transactions');
      final List<dynamic> data = response.data;
      return data.map((json) => TransactionModel.fromJson(json)).toList();
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Failed to fetch transactions',
      );
    }
  }

  // create transaction
  Future<void> createTransaction(Map<String, dynamic> data) async {
    try {
      await _apiClient.dio.post('/transactions', data: data);
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Failed to create transaction',
      );
    }
  }
}
