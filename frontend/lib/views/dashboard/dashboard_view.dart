import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/todo_provider.dart';
import '../../providers/time_tracking_provider.dart';
import '../../providers/asset_provider.dart';
import '../../providers/rss_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/dashboard/dashboard_layout.dart';
import 'cards/cards.dart';

class DashboardView extends ConsumerWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todosAsync = ref.watch(todoProvider);
    final sessionsAsync = ref.watch(timeTrackingProvider);
    final assetsAsync = ref.watch(assetProvider);
    final rssAsync = ref.watch(recentRssItemsProvider);
    final themeState = ref.watch(themeProvider);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: DashboardLayout(
          defaultColumns: 2,
          cards: [
            // Row 1: Stats
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Focus',
                    sessionsAsync.when(
                      data: (s) => s.isActive ? 'Active' : 'Idle',
                      loading: () => '...',
                      error: (_, __) => 'Error',
                    ),
                    Icons.timer,
                    themeState.seedColor,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Assets',
                    assetsAsync.when(
                      data: (a) => '${a.length}',
                      loading: () => '...',
                      error: (_, __) => '0',
                    ),
                    Icons.trending_up,
                    themeState.seedColor,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatCard(
                    context,
                    'RSS',
                    rssAsync.when(
                      data: (i) => '${i.length}',
                      loading: () => '...',
                      error: (_, __) => '0',
                    ),
                    Icons.rss_feed,
                    themeState.seedColor,
                  ),
                ),
              ],
            ),
            // Todo Card
            _buildTodoCard(context, ref, todosAsync),
            // Focus Card
            _buildFocusCard(context, ref, sessionsAsync),
            // Assets Card
            _buildAssetsCard(context, ref, assetsAsync),
            // RSS Card
            _buildRssCard(context, ref, rssAsync),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String label, String value, IconData icon, Color color) {
    return SizedBox(
      height: 100,
      child: Card(
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, size: 32, color: color),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(label, style: Theme.of(context).textTheme.bodySmall),
                    Text(value, style: Theme.of(context).textTheme.titleLarge),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTodoCard(BuildContext context, WidgetRef ref, AsyncValue todosAsync) {
    return SizedBox(
      height: 250,
      child: TodoCard(
        todos: todosAsync.when(
          data: (todos) => todos.map<Map<String, dynamic>>((t) => {
            'id': t.id,
            'title': t.title,
            'completed': t.completed,
            'priority': t.priority,
          }).toList(),
          loading: () => <Map<String, dynamic>>[],
          error: (_, __) => <Map<String, dynamic>>[],
        ),
        onToggle: (id, completed) {
          ref.read(todoProvider.notifier).toggleComplete(id, completed);
        },
        onViewAll: () => context.go('/time-management'),
      ),
    );
  }

  Widget _buildFocusCard(BuildContext context, WidgetRef ref, AsyncValue sessionsAsync) {
    final statsAsync = ref.watch(todayStatsProvider);
    
    return SizedBox(
      height: 200,
      child: FocusCard(
        isActive: sessionsAsync.valueOrNull?.isActive ?? false,
        taskName: sessionsAsync.valueOrNull?.session?.taskName,
        durationSeconds: sessionsAsync.valueOrNull?.session?.durationSeconds ?? 0,
        todayMinutes: statsAsync.valueOrNull?['total_minutes'] ?? 0,
      ),
    );
  }

  Widget _buildAssetsCard(BuildContext context, WidgetRef ref, AsyncValue assetsAsync) {
    return SizedBox(
      height: 250,
      child: AssetsCard(
        assets: assetsAsync.when(
          data: (assets) => assets.map<AssetInfo>((a) => AssetInfo(
            id: a.id,
            name: a.name,
            totalValue: a.totalValue,
            profitLoss: a.profitLoss,
          )).toList(),
          loading: () => <AssetInfo>[],
          error: (_, __) => <AssetInfo>[],
        ),
        onViewAll: () => context.go('/assets'),
      ),
    );
  }

  Widget _buildRssCard(BuildContext context, WidgetRef ref, AsyncValue rssAsync) {
    return SizedBox(
      height: 250,
      child: RssCard(
        items: rssAsync.when(
          data: (items) => items.map<RssItemInfo>((i) => RssItemInfo(
            title: i.title,
            summary: i.aiSummary,
            importance: i.aiImportance,
          )).toList(),
          loading: () => <RssItemInfo>[],
          error: (_, __) => <RssItemInfo>[],
        ),
        onViewAll: () => context.go('/rss'),
      ),
    );
  }
}
