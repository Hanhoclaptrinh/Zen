import 'package:dio/dio.dart';
import 'package:frontend/data/models/category_model.dart';
import 'package:frontend/data/services/api_client.dart';

class CategoryService {
  final ApiClient _apiClient;

  CategoryService(this._apiClient);

  Future<List<CategoryModel>> getCategories() async {
    try {
      final response = await _apiClient.dio.get('/categories');
      final List<dynamic> data = response.data;
      return data.map((json) => CategoryModel.fromJson(json)).toList();
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Failed to fetch categories',
      );
    }
  }

  Future<void> createCategory(String name, String type) async {
    try {
      await _apiClient.dio.post(
        '/categories',
        data: {'name': name, 'type': type},
      );
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Failed to create category',
      );
    }
  }
}
