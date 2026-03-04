import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../models/monitor.dart';

final serverMetricsProvider = FutureProvider<ServerMetrics>((ref) async {
  final apiClient = ref.watch(apiClientProvider);
  final response = await apiClient.get('/monitor/metrics');
  return ServerMetrics.fromJson(response.data);
});

final metricsHistoryProvider = FutureProvider.family<List<ServerMetrics>, int>((ref, hours) async {
  final apiClient = ref.watch(apiClientProvider);
  final response = await apiClient.get('/monitor/metrics/history', queryParameters: {'hours': hours});
  return (response.data as List).map((e) => ServerMetrics.fromJson(e)).toList();
});

class MonitorThresholdNotifier extends StateNotifier<AsyncValue<List<MonitorThreshold>>> {
  final ApiClient _apiClient;

  MonitorThresholdNotifier(this._apiClient) : super(const AsyncValue.loading()) {
    fetchThresholds();
  }

  Future<void> fetchThresholds() async {
    state = const AsyncValue.loading();
    try {
      final response = await _apiClient.get('/monitor/thresholds');
      final thresholds = (response.data as List).map((e) => MonitorThreshold.fromJson(e)).toList();
      state = AsyncValue.data(thresholds);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addThreshold(Map<String, dynamic> data) async {
    try {
      await _apiClient.post('/monitor/thresholds', data: data);
      await fetchThresholds();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateThreshold(int id, Map<String, dynamic> data) async {
    try {
      await _apiClient.put('/monitor/thresholds/$id', data: data);
      await fetchThresholds();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteThreshold(int id) async {
    try {
      await _apiClient.delete('/monitor/thresholds/$id');
      await fetchThresholds();
    } catch (e) {
      rethrow;
    }
  }
}

final monitorThresholdProvider = StateNotifierProvider<MonitorThresholdNotifier, AsyncValue<List<MonitorThreshold>>>((ref) {
  return MonitorThresholdNotifier(ref.watch(apiClientProvider));
});
