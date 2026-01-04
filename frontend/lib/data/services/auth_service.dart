import 'package:dio/dio.dart';
import 'package:frontend/data/models/user_model.dart';
import 'package:frontend/data/services/api_client.dart';

class AuthService {
  final ApiClient _apiClient;

  AuthService(this._apiClient);

  /// xu ly logic
  Future<String> login(String email, String password) async {
    try {
      final response = await _apiClient.dio.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );
      return response.data['accessToken']; // at duoc tra ve tu backend
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Login failed');
    }
  }

  // xu ly register
  Future<String> register(
    String fullName,
    String email,
    String password,
  ) async {
    try {
      final response = await _apiClient.dio.post(
        '/auth/register',
        data: {'fullName': fullName, 'email': email, 'password': password},
      );
      return response.data['accessToken'];
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Registration failed');
    }
  }

  Future<UserModel> getUserProfile() async {
    try {
      final response = await _apiClient.dio.get('/auth/profile');
      return UserModel.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to fetch profile');
    }
  }

  Future<UserModel> updateProfile(String fullName) async {
    try {
      final response = await _apiClient.dio.post(
        '/auth/profile',
        data: {'fullName': fullName},
      );
      return UserModel.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Failed to update profile',
      );
    }
  }

  Future<void> changePassword(String oldPassword, String newPassword) async {
    try {
      await _apiClient.dio.post(
        '/auth/change-password',
        data: {'oldPassword': oldPassword, 'newPassword': newPassword},
      );
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Failed to change password',
      );
    }
  }

  Future<void> forgotPassword(String email) async {
    try {
      await _apiClient.dio.post(
        '/auth/forgot-password',
        data: {'email': email},
      );
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to send OTP');
    }
  }

  Future<void> verifyOtp(String email, String otp) async {
    try {
      await _apiClient.dio.post(
        '/auth/verify-otp',
        data: {'email': email, 'otp': otp},
      );
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Invalid OTP');
    }
  }

  Future<void> resetPassword(
    String email,
    String otp,
    String newPassword,
  ) async {
    try {
      await _apiClient.dio.post(
        '/auth/reset-password',
        data: {'email': email, 'otp': otp, 'newPassword': newPassword},
      );
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Failed to reset password',
      );
    }
  }
}
