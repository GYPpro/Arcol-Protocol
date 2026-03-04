import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../providers/rss_provider.dart';

class RssView extends ConsumerStatefulWidget {
  const RssView({super.key});

  @override
  ConsumerState<RssView> createState() => _RssViewState();
}

class _RssViewState extends ConsumerState<RssView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _nameController = TextEditingController();
  final _urlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add RSS Feed'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Name')),
            const SizedBox(height: 16),
            TextField(controller: _urlController, decoration: const InputDecoration(labelText: 'URL')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (_nameController.text.isNotEmpty && _urlController.text.isNotEmpty) {
                ref.read(rssFeedProvider.notifier).addFeed({
                  'name': _nameController.text,
                  'url': _urlController.text,
                  'fetch_interval_minutes': 60,
                  'ai_analysis_enabled': true,
                  'importance_threshold': 0.7,
                });
                Navigator.pop(context);
                _nameController.clear();
                _urlController.clear();
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final feedsAsync = ref.watch(rssFeedProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('RSS Feeds'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Feeds', icon: Icon(Icons.rss_feed)),
            Tab(text: 'Items', icon: Icon(Icons.list)),
          ],
        ),
        actions: [IconButton(icon: const Icon(Icons.add), onPressed: _showAddDialog)],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          feedsAsync.when(
            data: (feeds) {
              if (feeds.isEmpty) return const Center(child: Text('No feeds configured'));
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: feeds.length,
                itemBuilder: (context, index) {
                  final feed = feeds[index];
                  return Card(
                    child: ListTile(
                      title: Text(feed.name),
                      subtitle: Text(feed.url),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.refresh),
                            onPressed: () async {
                              final count = await ref.read(rssFeedProvider.notifier).fetchFeed(feed.id);
                              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Fetched $count items')));
                            },
                          ),
                          IconButton(icon: const Icon(Icons.delete), onPressed: () => ref.read(rssFeedProvider.notifier).deleteFeed(feed.id)),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
          ),
          _buildItemsTab(),
        ],
      ),
    );
  }

  Widget _buildItemsTab() {
    final itemsAsync = ref.watch(recentRssItemsProvider);

    return itemsAsync.when(
      data: (items) {
        if (items.isEmpty) return const Center(child: Text('No items'));
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return Card(
              child: ListTile(
                title: Text(item.title, maxLines: 2, overflow: TextOverflow.ellipsis),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (item.aiSummary != null) Text(item.aiSummary!, maxLines: 2, overflow: TextOverflow.ellipsis),
                    if (item.aiCategory != null) Chip(label: Text(item.aiCategory!), visualDensity: VisualDensity.compact),
                  ],
                ),
                trailing: item.aiImportance != null ? Text('${(item.aiImportance! * 100).toInt()}%') : null,
                onTap: item.link != null ? () => launchUrl(Uri.parse(item.link!)) : null,
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}
