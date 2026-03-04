import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../models/todo.dart';

class TodoNotifier extends StateNotifier<AsyncValue<List<TodoItem>>> {
  final ApiClient _apiClient;

  TodoNotifier(this._apiClient) : super(const AsyncValue.loading()) {
    fetchTodos();
  }

  Future<void> fetchTodos({bool completed = false}) async {
    state = const AsyncValue.loading();
    try {
      final response = await _apiClient.get('/todos', queryParameters: {'completed': completed});
      final todos = (response.data as List).map((e) => TodoItem.fromJson(e)).toList();
      state = AsyncValue.data(todos);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addTodo(TodoItem todo) async {
    try {
      await _apiClient.post('/todos/', data: todo.toJson());
      await fetchTodos();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateTodo(int id, Map<String, dynamic> data) async {
    try {
      await _apiClient.put('/todos/$id', data: data);
      await fetchTodos();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteTodo(int id) async {
    try {
      await _apiClient.delete('/todos/$id');
      await fetchTodos();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> toggleComplete(int id, bool completed) async {
    await updateTodo(id, {'completed': completed});
  }
}

final todoProvider = StateNotifierProvider<TodoNotifier, AsyncValue<List<TodoItem>>>((ref) {
  return TodoNotifier(ref.watch(apiClientProvider));
});

final completedTodosProvider = FutureProvider<List<TodoItem>>((ref) async {
  final apiClient = ref.watch(apiClientProvider);
  final response = await apiClient.get('/todos', queryParameters: {'completed': true});
  return (response.data as List).map((e) => TodoItem.fromJson(e)).toList();
});
