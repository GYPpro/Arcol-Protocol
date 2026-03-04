import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/api_client.dart';
import '../config/config.dart';
import '../models/user.dart';

class AuthState {
  final User? user;
  final bool isLoading;
  final bool isAuthenticated;
  final String? error;

  AuthState({
    this.user,
    this.isLoading = false,
    this.isAuthenticated = false,
    this.error,
  });

  AuthState copyWith({
    User? user,
    bool? isLoading,
    bool? isAuthenticated,
    String? error,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      error: error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiClient _apiClient;

  AuthNotifier(this._apiClient) : super(AuthState()) {
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AppConfig.tokenKey);
    if (token != null) {
      try {
        final response = await _apiClient.get('/auth/me');
        state = state.copyWith(
          user: User.fromJson(response.data),
          isAuthenticated: true,
        );
      } catch (e) {
        await prefs.remove(AppConfig.tokenKey);
        state = AuthState();
      }
    }
  }

  Future<void> login(String username, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _apiClient.post('/auth/login', data: {
        'username': username,
        'password': password,
      });
      final token = Token.fromJson(response.data);
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConfig.tokenKey, token.accessToken);
      
      final userResponse = await _apiClient.get('/auth/me');
      state = state.copyWith(
        user: User.fromJson(userResponse.data),
        isAuthenticated: true,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Invalid username or password',
      );
    }
  }

  Future<void> register(String username, String password, String? email) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _apiClient.post('/auth/register', data: {
        'username': username,
        'password': password,
        'email': email,
      });
      await login(username, password);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Registration failed. Username may already exist.',
      );
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConfig.tokenKey);
    state = AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(apiClientProvider));
});
