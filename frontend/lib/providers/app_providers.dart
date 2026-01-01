import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/data/services/api_client.dart';
import 'package:frontend/data/services/auth_service.dart';

// providers
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

final authServiceProvider = Provider<AuthService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AuthService(apiClient);
});

// state providers
class AuthState {
  final bool isLoading;
  final String? error;
  final String? token;

  AuthState({this.isLoading = false, this.error, this.token});

  AuthState copyWith({bool? isLoading, String? error, String? token}) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      token: token ?? this.token,
    );
  }
}

class AuthController extends Notifier<AuthState> {
  late AuthService _authService;
  late ApiClient _apiClient;

  @override
  AuthState build() {
    _authService = ref.read(authServiceProvider);
    _apiClient = ref.read(apiClientProvider);
    return AuthState();
  }

  // xu ly login
  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final token = await _authService.login(email, password);
      _apiClient.setToken(token);
      state = AuthState(isLoading: false, token: token);
      return true;
    } catch (e) {
      state = AuthState(isLoading: false, error: e.toString());
      return false;
    }
  }

  // xu ly register
  Future<bool> register(String fullName, String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final token = await _authService.register(fullName, email, password);
      _apiClient.setToken(token);
      state = AuthState(isLoading: false, token: token);
      return true;
    } catch (e) {
      state = AuthState(isLoading: false, error: e.toString());
      return false;
    }
  }

  // xu ly logout
  void logout() {
    _apiClient.clearToken();
    state = AuthState();
  }
}

// controller provider
final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);
