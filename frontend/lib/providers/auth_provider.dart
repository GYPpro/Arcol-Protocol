import 'dart:developer' as developer;
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
    developer.log('[AUTH] Checking auth...', name: 'AuthProvider');
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AppConfig.tokenKey);
    developer.log('[AUTH] Token found: ${token != null}', name: 'AuthProvider');
    if (token != null) {
      try {
        final response = await _apiClient.get('/auth/me');
        state = state.copyWith(
          user: User.fromJson(response.data),
          isAuthenticated: true,
        );
      } catch (e) {
        developer.log('[AUTH] Token invalid, clearing...', name: 'AuthProvider');
        await prefs.remove(AppConfig.tokenKey);
        state = AuthState();
      }
    }
  }

  Future<void> login(String username, String password) async {
    developer.log('[AUTH] Login attempt: $username', name: 'AuthProvider');
    state = state.copyWith(isLoading: true, error: null);
    try {
      developer.log('[AUTH] Calling API...', name: 'AuthProvider');
      final response = await _apiClient.postForm('/auth/login', data: {
        'username': username,
        'password': password,
      });
      developer.log('[AUTH] Response: ${response.data}', name: 'AuthProvider');
      final token = Token.fromJson(response.data);
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConfig.tokenKey, token.accessToken);
      
      final userResponse = await _apiClient.get('/auth/me');
      state = state.copyWith(
        user: User.fromJson(userResponse.data),
        isAuthenticated: true,
        isLoading: false,
      );
      developer.log('[AUTH] Login success!', name: 'AuthProvider');
    } catch (e, stack) {
      developer.log('[AUTH] Login error: $e', name: 'AuthProvider');
      developer.log('[AUTH] Stack: $stack', name: 'AuthProvider');
      state = state.copyWith(
        isLoading: false,
        error: 'Invalid username or password: $e',
      );
    }
  }

  Future<void> register(String username, String password, String? email) async {
    developer.log('[AUTH] Register attempt: $username', name: 'AuthProvider');
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _apiClient.post('/auth/register', data: {
        'username': username,
        'password': password,
        'email': email,
      });
      developer.log('[AUTH] Registration success, logging in...', name: 'AuthProvider');
      await login(username, password);
    } catch (e, stack) {
      developer.log('[AUTH] Register error: $e', name: 'AuthProvider');
      developer.log('[AUTH] Stack: $stack', name: 'AuthProvider');
      state = state.copyWith(
        isLoading: false,
        error: 'Registration failed: $e',
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
