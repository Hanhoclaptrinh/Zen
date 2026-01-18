import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:frontend/data/models/user_model.dart';
import 'package:frontend/data/services/api_client.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final ApiClient _apiClient;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  AuthService(this._apiClient);

  // dang nhap bang google
  Future<String?> signInWithGoogle() async {
    try {
      // lay credential tu google
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // dang nhap vao firebase
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );

      // lay firebase ID token
      final String? firebaseIdToken = await userCredential.user?.getIdToken();

      if (firebaseIdToken == null) {
        throw Exception('Could not get Firebase ID Token');
      }

      // gui firebaseIdToken ve backend
      final response = await _apiClient.dio.post(
        '/auth/google-sign-in',
        data: {'idToken': firebaseIdToken},
      );
      return response.data['accessToken'];
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Google Login to Backend failed',
      );
    } catch (e) {
      throw Exception('Google Sign-In failed: $e');
    }
  }

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

  Future<UserModel> updateProfile({String? fullName, String? avatar}) async {
    try {
      final data = <String, dynamic>{};
      if (fullName != null) data['fullName'] = fullName;
      if (avatar != null) data['avatarUrl'] = avatar;

      final response = await _apiClient.dio.patch('/auth/profile', data: data);
      return UserModel.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Failed to update profile',
      );
    }
  }

  Future<void> changePassword(String oldPassword, String newPassword) async {
    try {
      await _apiClient.dio.patch(
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
