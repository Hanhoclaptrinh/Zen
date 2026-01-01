import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/data/models/category_model.dart';
import 'package:frontend/data/models/transaction_model.dart';
import 'package:frontend/data/models/user_model.dart';
import 'package:frontend/data/services/api_client.dart';
import 'package:frontend/data/services/auth_service.dart';
import 'package:frontend/data/services/category_service.dart';
import 'package:frontend/data/services/transaction_service.dart';

// providers
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

final authServiceProvider = Provider<AuthService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AuthService(apiClient);
});

final transactionServiceProvider = Provider<TransactionService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return TransactionService(apiClient);
});

final categoryServiceProvider = Provider<CategoryService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return CategoryService(apiClient);
});

// auth state
class AuthState {
  final bool isLoading;
  final String? error;
  final bool isAuthenticated;
  final UserModel? user;

  AuthState({
    this.isLoading = false,
    this.error,
    this.isAuthenticated = false,
    this.user,
  });

  AuthState copyWith({
    bool? isLoading,
    String? error,
    bool? isAuthenticated,
    UserModel? user,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      user: user ?? this.user,
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

  Future<void> fetchProfile() async {
    try {
      final user = await _authService.getUserProfile();
      state = state.copyWith(user: user, isAuthenticated: true);
    } catch (e) {
      state = state.copyWith(error: "Failed to load profile");
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final token = await _authService.login(email, password);
      _apiClient.setToken(token);
      state = AuthState(isLoading: false, isAuthenticated: true);
      await fetchProfile();
      return true;
    } catch (e) {
      state = AuthState(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> register(String fullName, String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final token = await _authService.register(fullName, email, password);
      _apiClient.setToken(token);
      state = AuthState(isLoading: false, isAuthenticated: true);
      await fetchProfile();
      return true;
    } catch (e) {
      state = AuthState(isLoading: false, error: e.toString());
      return false;
    }
  }

  void logout() {
    _apiClient.clearToken();
    state = AuthState();
  }
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);

// trans state
enum FilterMode { day, month }

class TransactionState {
  final bool isLoading;
  final String? error;
  final List<TransactionModel> allTransactions;
  final List<TransactionModel> filteredTransactions;
  final FilterMode filterMode;
  final DateTime selectedDate;

  TransactionState({
    this.isLoading = false,
    this.error,
    this.allTransactions = const [],
    this.filteredTransactions = const [],
    this.filterMode = FilterMode.month,
    required this.selectedDate,
  });

  TransactionState copyWith({
    bool? isLoading,
    String? error,
    List<TransactionModel>? allTransactions,
    List<TransactionModel>? filteredTransactions,
    FilterMode? filterMode,
    DateTime? selectedDate,
  }) {
    return TransactionState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      allTransactions: allTransactions ?? this.allTransactions,
      filteredTransactions: filteredTransactions ?? this.filteredTransactions,
      filterMode: filterMode ?? this.filterMode,
      selectedDate: selectedDate ?? this.selectedDate,
    );
  }

  // get total income and expense
  double get totalIncome => filteredTransactions
      .where((t) => t.type == 'income')
      .fold(0.0, (sum, t) => sum + t.amount);

  double get totalExpense => filteredTransactions
      .where((t) => t.type == 'expense')
      .fold(0.0, (sum, t) => sum + t.amount);

  double get balance => totalIncome - totalExpense;
}

class TransactionController extends Notifier<TransactionState> {
  late TransactionService _service;

  @override
  TransactionState build() {
    _service = ref.read(transactionServiceProvider);
    return TransactionState(selectedDate: DateTime.now());
  }

  Future<void> fetchTransactions() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final transactions = await _service.getTransactions();
      state = state.copyWith(isLoading: false, allTransactions: transactions);
      _applyFilter();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> addTransaction(Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _service.createTransaction(data);
      await fetchTransactions();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  void setFilterMode(FilterMode mode) {
    state = state.copyWith(filterMode: mode);
    _applyFilter();
  }

  void setSelectedDate(DateTime date) {
    state = state.copyWith(selectedDate: date);
    _applyFilter();
  }

  void _applyFilter() {
    final mode = state.filterMode;
    final date = state.selectedDate;

    final filtered = state.allTransactions.where((t) {
      if (mode == FilterMode.day) {
        return t.transactionDate.year == date.year &&
            t.transactionDate.month == date.month &&
            t.transactionDate.day == date.day;
      } else {
        return t.transactionDate.year == date.year &&
            t.transactionDate.month == date.month;
      }
    }).toList();

    filtered.sort((a, b) => b.transactionDate.compareTo(a.transactionDate));

    state = state.copyWith(filteredTransactions: filtered);
  }
}

final transactionControllerProvider =
    NotifierProvider<TransactionController, TransactionState>(
      TransactionController.new,
    );

// category state
class CategoryState {
  final bool isLoading;
  final List<CategoryModel> categories;
  final String? error;

  CategoryState({
    this.isLoading = false,
    this.categories = const [],
    this.error,
  });
}

class CategoryController extends Notifier<CategoryState> {
  late CategoryService _service;

  @override
  CategoryState build() {
    _service = ref.read(categoryServiceProvider);
    return CategoryState();
  }

  Future<void> fetchCategories() async {
    state = CategoryState(isLoading: true);
    try {
      final categories = await _service.getCategories();
      state = CategoryState(isLoading: false, categories: categories);
    } catch (e) {
      state = CategoryState(isLoading: false, error: e.toString());
    }
  }

  Future<bool> addCategory(String name, String type) async {
    try {
      await _service.createCategory(name, type);
      await fetchCategories();
      return true;
    } catch (e) {
      return false;
    }
  }
}

final categoryControllerProvider =
    NotifierProvider<CategoryController, CategoryState>(CategoryController.new);
