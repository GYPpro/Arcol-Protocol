import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';
import '../../providers/todo_provider.dart';
import '../../providers/time_tracking_provider.dart';
import '../../providers/asset_provider.dart';
import '../../providers/rss_provider.dart';
import '../../providers/monitor_provider.dart';

class DashboardView extends ConsumerStatefulWidget {
  const DashboardView({super.key});

  @override
  ConsumerState<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends ConsumerState<DashboardView> {
  int _selectedIndex = 0;

  final _navItems = const [
    (Icons.dashboard, 'Dashboard', '/dashboard'),
    (Icons.timer, 'Time', '/time-management'),
    (Icons.trending_up, 'Assets', '/assets'),
    (Icons.dns, 'Routes', '/site-routes'),
    (Icons.monitor_heart, 'Monitor', '/server-monitor'),
    (Icons.rss_feed, 'RSS', '/rss'),
    (Icons.settings, 'Settings', '/settings'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              setState(() => _selectedIndex = index);
              context.go(_navItems[index].$3);
            },
            labelType: NavigationRailLabelType.all,
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                children: [
                  const Icon(Icons.dashboard_rounded, size: 32),
                  const SizedBox(height: 4),
                  Text(
                    'Arcol',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
            ),
            trailing: Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: IconButton(
                    icon: const Icon(Icons.logout),
                    onPressed: () {
                      ref.read(authProvider.notifier).logout();
                      context.go('/guest');
                    },
                  ),
                ),
              ),
            ),
            destinations: _navItems.map((item) => NavigationRailDestination(
              icon: Icon(item.$1),
              selectedIcon: Icon(item.$1),
              label: Text(item.$2),
            )).toList(),
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dashboard',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 24),
          _buildQuickStats(),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildTodosCard()),
              const SizedBox(width: 16),
              Expanded(child: _buildFocusCard()),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildAssetsOverview()),
              const SizedBox(width: 16),
              Expanded(child: _buildRecentRssCard()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    final assetsAsync = ref.watch(assetProvider);
    final thresholdsAsync = ref.watch(monitorThresholdProvider);
    final rssFeedsAsync = ref.watch(rssFeedProvider);
    final sessionsAsync = ref.watch(timeTrackingProvider);

    return Row(
      children: [
        _buildStatCard(
          'Focus',
          sessionsAsync.when(
            data: (s) => s.isActive ? 'Active' : 'Idle',
            loading: () => '...',
            error: (_, __) => 'Error',
          ),
          Icons.timer,
          Colors.blue,
        ),
        const SizedBox(width: 16),
        _buildStatCard(
          'Assets',
          assetsAsync.when(
            data: (a) => '${a.length}',
            loading: () => '...',
            error: (_, __) => '0',
          ),
          Icons.trending_up,
          Colors.green,
        ),
        const SizedBox(width: 16),
        _buildStatCard(
          'RSS Feeds',
          rssFeedsAsync.when(
            data: (f) => '${f.length}',
            loading: () => '...',
            error: (_, __) => '0',
          ),
          Icons.rss_feed,
          Colors.orange,
        ),
        const SizedBox(width: 16),
        _buildStatCard(
          'Alerts',
          thresholdsAsync.when(
            data: (t) => '${t.length}',
            loading: () => '...',
            error: (_, __) => '0',
          ),
          Icons.warning,
          Colors.red,
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: Theme.of(context).textTheme.bodySmall),
                  Text(value, style: Theme.of(context).textTheme.titleLarge),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTodosCard() {
    final todosAsync = ref.watch(todoProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Pending Tasks', style: Theme.of(context).textTheme.titleMedium),
                TextButton(
                  onPressed: () => context.go('/time-management'),
                  child: const Text('View All'),
                ),
              ],
            ),
            const Divider(),
            todosAsync.when(
              data: (todos) {
                final pending = todos.where((t) => !t.completed).take(5).toList();
                if (pending.isEmpty) return const Text('No pending tasks');
                return Column(
                  children: pending.map((todo) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Checkbox(
                      value: todo.completed,
                      onChanged: (v) {
                        ref.read(todoProvider.notifier).toggleComplete(todo.id, v ?? false);
                      },
                    ),
                    title: Text(todo.title),
                    subtitle: Text('Priority: ${todo.priority}'),
                  )).toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error: $e'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFocusCard() {
    final sessionsAsync = ref.watch(timeTrackingProvider);
    final statsAsync = ref.watch(todayStatsProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Time Tracking', style: Theme.of(context).textTheme.titleMedium),
            const Divider(),
            sessionsAsync.when(
              data: (session) {
                if (session.isActive && session.session != null) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Currently working on:', style: Theme.of(context).textTheme.bodySmall),
                      Text(session.session!.taskName, style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 8),
                      Text(
                        _formatDuration(session.session!.durationSeconds),
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('No active session'),
                    const SizedBox(height: 8),
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
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error: $e'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssetsOverview() {
    final assetsAsync = ref.watch(assetProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Assets Overview', style: Theme.of(context).textTheme.titleMedium),
                TextButton(
                  onPressed: () => context.go('/assets'),
                  child: const Text('View All'),
                ),
              ],
            ),
            const Divider(),
            assetsAsync.when(
              data: (assets) {
                if (assets.isEmpty) return const Text('No assets configured');
                final total = assets.fold<double>(0, (sum, a) => sum + a.totalValue);
                return Column(
                  children: [
                    Text(
                      '\$${total.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    ...assets.take(3).map((asset) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(asset.name),
                      trailing: Text(
                        '\$${asset.totalValue.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: asset.profitLoss >= 0 ? Colors.green : Colors.red,
                        ),
                      ),
                    )),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error: $e'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentRssCard() {
    final rssAsync = ref.watch(recentRssItemsProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Recent RSS', style: Theme.of(context).textTheme.titleMedium),
                TextButton(
                  onPressed: () => context.go('/rss'),
                  child: const Text('View All'),
                ),
              ],
            ),
            const Divider(),
            rssAsync.when(
              data: (items) {
                if (items.isEmpty) return const Text('No recent items');
                return Column(
                  children: items.take(5).map((item) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(item.title, maxLines: 2, overflow: TextOverflow.ellipsis),
                    subtitle: item.aiSummary != null
                        ? Text(item.aiSummary!, maxLines: 1, overflow: TextOverflow.ellipsis)
                        : null,
                  )).toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error: $e'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}
