import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../models/todo.dart';

class TimeTrackingNotifier extends StateNotifier<AsyncValue<TimeSessionActive>> {
  final ApiClient _apiClient;

  TimeTrackingNotifier(this._apiClient) : super(const AsyncValue.loading()) {
    fetchActiveSession();
  }

  Future<void> fetchActiveSession() async {
    try {
      final response = await _apiClient.get('/time-tracking/sessions/active');
      state = AsyncValue.data(TimeSessionActive.fromJson(response.data));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> startSession(String taskName, String? description) async {
    try {
      await _apiClient.post('/time-tracking/sessions', data: {
        'task_name': taskName,
        'description': description,
      });
      await fetchActiveSession();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> stopSession(int sessionId) async {
    try {
      await _apiClient.put('/time-tracking/sessions/$sessionId/stop');
      await fetchActiveSession();
    } catch (e) {
      rethrow;
    }
  }
}

final timeTrackingProvider = StateNotifierProvider<TimeTrackingNotifier, AsyncValue<TimeSessionActive>>((ref) {
  return TimeTrackingNotifier(ref.watch(apiClientProvider));
});

final timeSessionsProvider = FutureProvider<List<TimeSession>>((ref) async {
  final apiClient = ref.watch(apiClientProvider);
  final response = await apiClient.get('/time-tracking/sessions');
  return (response.data as List).map((e) => TimeSession.fromJson(e)).toList();
});

final todayStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final apiClient = ref.watch(apiClientProvider);
  final response = await apiClient.get('/time-tracking/stats/today');
  return response.data;
});
