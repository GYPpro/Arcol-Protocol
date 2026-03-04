import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../models/asset.dart';

class AssetNotifier extends StateNotifier<AsyncValue<List<Asset>>> {
  final ApiClient _apiClient;

  AssetNotifier(this._apiClient) : super(const AsyncValue.loading()) {
    fetchAssets();
  }

  Future<void> fetchAssets() async {
    state = const AsyncValue.loading();
    try {
      final response = await _apiClient.get('/assets');
      final assets = (response.data as List).map((e) => Asset.fromJson(e)).toList();
      state = AsyncValue.data(assets);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addAsset(Map<String, dynamic> data) async {
    try {
      await _apiClient.post('/assets/', data: data);
      await fetchAssets();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateAsset(int id, Map<String, dynamic> data) async {
    try {
      await _apiClient.put('/assets/$id', data: data);
      await fetchAssets();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteAsset(int id) async {
    try {
      await _apiClient.delete('/assets/$id');
      await fetchAssets();
    } catch (e) {
      rethrow;
    }
  }
}

final assetProvider = StateNotifierProvider<AssetNotifier, AsyncValue<List<Asset>>>((ref) {
  return AssetNotifier(ref.watch(apiClientProvider));
});
