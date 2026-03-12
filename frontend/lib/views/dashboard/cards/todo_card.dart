import 'package:flutter/material.dart';
import '../../../widgets/dashboard/base_card.dart';

class TodoCard extends StatelessWidget {
  final List<Map<String, dynamic>> todos;
  final void Function(int id, bool completed)? onToggle;
  final VoidCallback? onViewAll;

  const TodoCard({
    super.key,
    required this.todos,
    this.onToggle,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    final pending = todos.where((t) => t['completed'] != true).take(5).toList();

    return DashboardCard(
      title: 'Pending Tasks',
      icon: Icons.checklist,
      trailing: onViewAll != null
          ? TextButton(onPressed: onViewAll, child: const Text('View All'))
          : null,
      child: pending.isEmpty
          ? const Center(child: Text('No pending tasks'))
          : ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: pending.length,
              itemBuilder: (context, index) {
                final todo = pending[index];
                return CheckboxListTile(
                  value: todo['completed'] ?? false,
                  onChanged: (v) => onToggle?.call(todo['id'] as int, v ?? false),
                  title: Text(todo['title']?.toString() ?? ''),
                  subtitle: Text('Priority: ${todo['priority']}'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                );
              },
            ),
    );
  }
}
