import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../models/rss.dart';

class RssFeedNotifier extends StateNotifier<AsyncValue<List<RssFeed>>> {
  final ApiClient _apiClient;

  RssFeedNotifier(this._apiClient) : super(const AsyncValue.loading()) {
    fetchFeeds();
  }

  Future<void> fetchFeeds() async {
    state = const AsyncValue.loading();
    try {
      final response = await _apiClient.get('/rss/feeds');
      final feeds = (response.data as List).map((e) => RssFeed.fromJson(e)).toList();
      state = AsyncValue.data(feeds);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addFeed(Map<String, dynamic> data) async {
    try {
      await _apiClient.post('/rss/feeds', data: data);
      await fetchFeeds();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateFeed(int id, Map<String, dynamic> data) async {
    try {
      await _apiClient.put('/rss/feeds/$id', data: data);
      await fetchFeeds();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteFeed(int id) async {
    try {
      await _apiClient.delete('/rss/feeds/$id');
      await fetchFeeds();
    } catch (e) {
      rethrow;
    }
  }

  Future<int> fetchFeed(int id) async {
    try {
      final response = await _apiClient.post('/rss/feeds/$id/fetch');
      return response.data['entries_added'] ?? 0;
    } catch (e) {
      rethrow;
    }
  }
}

final rssFeedProvider = StateNotifierProvider<RssFeedNotifier, AsyncValue<List<RssFeed>>>((ref) {
  return RssFeedNotifier(ref.watch(apiClientProvider));
});

final rssItemsProvider = FutureProvider.family<List<RssItem>, int>((ref, feedId) async {
  final apiClient = ref.watch(apiClientProvider);
  final response = await apiClient.get('/rss/feeds/$feedId/items');
  return (response.data as List).map((e) => RssItem.fromJson(e)).toList();
});

final recentRssItemsProvider = FutureProvider<List<RssItem>>((ref) async {
  final apiClient = ref.watch(apiClientProvider);
  final response = await apiClient.get('/rss/items/recent', queryParameters: {'limit': 10});
  return (response.data as List).map((e) => RssItem.fromJson(e)).toList();
});
