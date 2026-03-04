import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../models/site_route.dart';

class SiteRouteNotifier extends StateNotifier<AsyncValue<List<SiteRoute>>> {
  final ApiClient _apiClient;

  SiteRouteNotifier(this._apiClient) : super(const AsyncValue.loading()) {
    fetchRoutes();
  }

  Future<void> fetchRoutes({String? group, String? tag}) async {
    state = const AsyncValue.loading();
    try {
      final queryParams = <String, dynamic>{};
      if (group != null) queryParams['group'] = group;
      if (tag != null) queryParams['tag'] = tag;
      
      final response = await _apiClient.get('/site-routes', queryParameters: queryParams);
      final routes = (response.data as List).map((e) => SiteRoute.fromJson(e)).toList();
      state = AsyncValue.data(routes);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addRoute(Map<String, dynamic> data) async {
    try {
      await _apiClient.post('/site-routes/', data: data);
      await fetchRoutes();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateRoute(int id, Map<String, dynamic> data) async {
    try {
      await _apiClient.put('/site-routes/$id', data: data);
      await fetchRoutes();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteRoute(int id) async {
    try {
      await _apiClient.delete('/site-routes/$id');
      await fetchRoutes();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> refreshStatus(int id) async {
    try {
      await _apiClient.post('/site-routes/$id/refresh-status');
      await fetchRoutes();
    } catch (e) {
      rethrow;
    }
  }
}

final siteRouteProvider = StateNotifierProvider<SiteRouteNotifier, AsyncValue<List<SiteRoute>>>((ref) {
  return SiteRouteNotifier(ref.watch(apiClientProvider));
});
