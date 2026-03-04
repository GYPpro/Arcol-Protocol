import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/todo_provider.dart';
import '../../providers/time_tracking_provider.dart';

class TimeManagementView extends ConsumerStatefulWidget {
  const TimeManagementView({super.key});

  @override
  ConsumerState<TimeManagementView> createState() => _TimeManagementViewState();
}

class _TimeManagementViewState extends ConsumerState<TimeManagementView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Timer? _timer;
  int _elapsedSeconds = 0;
  final _taskNameController = TextEditingController();
  final _taskDescController = TextEditingController();
  final _todoTitleController = TextEditingController();
  int _todoPriority = 3;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _timer?.cancel();
    _taskNameController.dispose();
    _taskDescController.dispose();
    _todoTitleController.dispose();
    super.dispose();
  }

  void _startTimer(int sessionId) {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _elapsedSeconds++);
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
    _elapsedSeconds = 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Time Management'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Time Tracking', icon: Icon(Icons.timer)),
            Tab(text: 'Todo List', icon: Icon(Icons.checklist)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTimeTrackingTab(),
          _buildTodoTab(),
        ],
      ),
    );
  }

  Widget _buildTimeTrackingTab() {
    final sessionsAsync = ref.watch(timeTrackingProvider);
    final statsAsync = ref.watch(todayStatsProvider);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  sessionsAsync.when(
                    data: (session) {
                      if (session.isActive && session.session != null) {
                        return Column(
                          children: [
                            Text('Working on:', style: Theme.of(context).textTheme.titleMedium),
                            Text(session.session!.taskName, style: Theme.of(context).textTheme.headlineSmall),
                            const SizedBox(height: 16),
                            StreamBuilder(
                              stream: Stream.periodic(const Duration(seconds: 1)),
                              builder: (context, snapshot) {
                                final seconds = session.session!.durationSeconds + 
                                    (session.session!.endTime == null 
                                        ? DateTime.now().difference(session.session!.startTime).inSeconds 
                                        : 0);
                                return Text(
                                  _formatDuration(seconds),
                                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                                    color: Colors.blue,
                                    fontWeight: FontWeight.bold,
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 16),
                            FilledButton.icon(
                              onPressed: () {
                                ref.read(timeTrackingProvider.notifier).stopSession(session.session!.id);
                              },
                              icon: const Icon(Icons.stop),
                              label: const Text('Stop'),
                              style: FilledButton.styleFrom(backgroundColor: Colors.red),
                            ),
                          ],
                        );
                      }
                      return Column(
                        children: [
                          const Text('No active session'),
                          const SizedBox(height: 16),
                          statsAsync.when(
                            data: (stats) => Text(
                              'Today: ${(stats['total_minutes'] ?? 0)} min',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            loading: () => const SizedBox(),
                            error: (_, __) => const SizedBox(),
                          ),
                        ],
                      );
                    },
                    loading: () => const CircularProgressIndicator(),
                    error: (e, _) => Text('Error: $e'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (sessionsAsync.valueOrNull?.isActive != true)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Start New Session', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _taskNameController,
                      decoration: const InputDecoration(
                        labelText: 'Task Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _taskDescController,
                      decoration: const InputDecoration(
                        labelText: 'Description (optional)',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () {
                          if (_taskNameController.text.isNotEmpty) {
                            ref.read(timeTrackingProvider.notifier).startSession(
                              _taskNameController.text,
                              _taskDescController.text.isEmpty ? null : _taskDescController.text,
                            );
                            _taskNameController.clear();
                            _taskDescController.clear();
                          }
                        },
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Start'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTodoTab() {
    final todosAsync = ref.watch(todoProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Add New Todo', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: _todoTitleController,
                          decoration: const InputDecoration(
                            labelText: 'Title',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          initialValue: _todoPriority,
                          decoration: const InputDecoration(
                            labelText: 'Priority',
                            border: OutlineInputBorder(),
                          ),
                          items: [1, 2, 3, 4, 5].map((p) => DropdownMenuItem(
                            value: p,
                            child: Text('$p'),
                          )).toList(),
                          onChanged: (v) => setState(() => _todoPriority = v ?? 3),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () {
                        if (_todoTitleController.text.isNotEmpty) {
                          ref.read(todoProvider.notifier).addTodo(
                            _createTodo(_todoTitleController.text, _todoPriority),
                          );
                          _todoTitleController.clear();
                        }
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Add Todo'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: todosAsync.when(
            data: (todos) {
              final pending = todos.where((t) => !t.completed).toList();
              if (pending.isEmpty) return const Center(child: Text('No pending todos'));
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: pending.length,
                itemBuilder: (context, index) {
                  final todo = pending[index];
                  return Card(
                    child: ListTile(
                      leading: Checkbox(
                        value: todo.completed,
                        onChanged: (v) {
                          ref.read(todoProvider.notifier).toggleComplete(todo.id, v ?? false);
                        },
                      ),
                      title: Text(todo.title),
                      subtitle: Text('Priority: ${todo.priority}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          ref.read(todoProvider.notifier).deleteTodo(todo.id);
                        },
                      ),
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
          ),
        ),
      ],
    );
  }

  dynamic _createTodo(String title, int priority) {
    return _TodoItemCreate(title: title, priority: priority);
  }

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}

class _TodoItemCreate {
  final String title;
  final int priority;

  _TodoItemCreate({required this.title, required this.priority});

  Map<String, dynamic> toJson() => {'title': title, 'priority': priority};
}
