import 'package:flutter/material.dart';
import '../../../widgets/dashboard/base_card.dart';

class RssItemInfo {
  final String title;
  final String? summary;
  final double? importance;

  RssItemInfo({
    required this.title,
    this.summary,
    this.importance,
  });
}

class RssCard extends StatelessWidget {
  final List<RssItemInfo> items;
  final VoidCallback? onViewAll;

  const RssCard({
    super.key,
    required this.items,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return DashboardCard(
      title: 'Recent RSS',
      icon: Icons.rss_feed,
      trailing: onViewAll != null
          ? TextButton(onPressed: onViewAll, child: const Text('View All'))
          : null,
      child: items.isEmpty
          ? const Center(child: Text('No recent items'))
          : ListView.builder(
              shrinkWrap: true,
              itemCount: items.take(5).length,
              itemBuilder: (context, index) {
                final item = items[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: item.summary != null
                      ? Text(
                          item.summary!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        )
                      : null,
                  trailing: item.importance != null
                      ? Text('${(item.importance! * 100).toInt()}%')
                      : null,
                );
              },
            ),
    );
  }
}
