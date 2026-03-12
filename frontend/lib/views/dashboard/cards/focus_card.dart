import 'package:flutter/material.dart';
import '../../../widgets/dashboard/base_card.dart';

class FocusCard extends StatelessWidget {
  final bool isActive;
  final String? taskName;
  final int durationSeconds;
  final int todayMinutes;

  const FocusCard({
    super.key,
    this.isActive = false,
    this.taskName,
    this.durationSeconds = 0,
    this.todayMinutes = 0,
  });

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return DashboardCard(
      title: 'Time Tracking',
      icon: Icons.timer,
      child: isActive && taskName != null
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Currently working on:',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 4),
                Text(
                  taskName!,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  _formatDuration(durationSeconds),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('No active session'),
                const SizedBox(height: 8),
                Text(
                  'Today: $todayMinutes min',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
    );
  }
}
