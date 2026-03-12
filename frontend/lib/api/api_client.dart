import 'dart:developer' as developer;
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/config.dart';

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
    baseUrl: '${AppConfig.baseUrl}${AppConfig.apiVersion}',
    connectTimeout: AppConfig.apiTimeout,
    receiveTimeout: AppConfig.apiTimeout,
    headers: {
      'Content-Type': 'application/json',
    },
  ));

  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) async {
      developer.log('[API] ${options.method} ${options.path}', name: 'ApiClient');
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(AppConfig.tokenKey);
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      return handler.next(options);
    },
    onError: (error, handler) {
      developer.log('[API] Error: ${error.message}', name: 'ApiClient');
      return handler.next(error);
    },
  ));

  return dio;
});

class ApiClient {
  final Dio _dio;

  ApiClient(this._dio);

  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) {
    developer.log('[API] GET $path', name: 'ApiClient');
    return _dio.get(path, queryParameters: queryParameters);
  }

  Future<Response> post(String path, {dynamic data}) {
    developer.log('[API] POST $path data: $data', name: 'ApiClient');
    return _dio.post(path, data: data);
  }

  Future<Response> postForm(String path, {required Map<String, dynamic> data}) {
    developer.log('[API] POST FORM $path data: $data', name: 'ApiClient');
    return _dio.post(
      path,
      data: FormData.fromMap(data),
      options: Options(
        contentType: 'application/x-www-form-urlencoded',
      ),
    );
  }

  Future<Response> put(String path, {dynamic data}) {
    developer.log('[API] PUT $path', name: 'ApiClient');
    return _dio.put(path, data: data);
  }

  Future<Response> delete(String path) {
    developer.log('[API] DELETE $path', name: 'ApiClient');
    return _dio.delete(path);
  }
}

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(ref.watch(dioProvider));
});
