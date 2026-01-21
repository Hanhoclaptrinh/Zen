import 'package:frontend/data/services/api_client.dart';
import 'dart:io';

class NotificationService {
  final ApiClient _apiClient;

  NotificationService(this._apiClient);

  Future<void> registerDevice(String token) async {
    final platform = Platform.isIOS ? 'ios' : 'android';
    await _apiClient.dio.post(
      '/notification/register-device',
      data: {'token': token, 'platform': platform},
    );
  }

  Future<void> unregisterDevice(String token) async {
    await _apiClient.dio.post(
      '/notification/unregister-device',
      data: {'token': token},
    );
  }
}
