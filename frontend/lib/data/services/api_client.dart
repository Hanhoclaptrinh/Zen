import 'package:dio/dio.dart';
import 'package:frontend/core/constants/app_constants.dart';

class ApiClient {
  final Dio _dio;

  // su dung dio de tao client api
  ApiClient()
    : _dio = Dio(
        BaseOptions(
          baseUrl: AppConstants.baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
          headers: {'Content-Type': 'application/json'},
        ),
      ) {
    _dio.interceptors.add(
      LogInterceptor(
        request: true,
        requestBody: true,
        responseBody: true,
        error: true,
      ),
    );
  }

  Dio get dio => _dio;

  // set auth token
  void setToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  // clear auth token
  void clearToken() {
    _dio.options.headers.remove('Authorization');
  }
}
