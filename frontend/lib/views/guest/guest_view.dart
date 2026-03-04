import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../api/api_client.dart';
import '../../config/config.dart';
import '../../models/todo.dart';
import '../../models/asset.dart';
import '../../models/site_route.dart';
import '../../models/rss.dart';

class GuestView extends ConsumerStatefulWidget {
  const GuestView({super.key});

  @override
  ConsumerState<GuestView> createState() => _GuestViewState();
}

class _GuestViewState extends ConsumerState<GuestView> {
  Timer? _timer;
  TimeSessionActive? _activeSession;
  List<Asset> _assets = [];
  List<SiteRoute> _routes = [];
  List<RssItem> _rssItems = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
    _timer = Timer.periodic(AppConfig.pollInterval, (_) => _fetchData());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchData() async {
    try {
      final dio = ref.read(dioProvider);
      
      final sessionRes = await dio.get('/time-tracking/sessions/active');
      final assetsRes = await dio.get('/assets');
      final routesRes = await dio.get('/site-routes');
      final rssRes = await dio.get('/rss/items/recent', queryParameters: {'limit': 5});

      if (mounted) {
        setState(() {
          _activeSession = TimeSessionActive.fromJson(sessionRes.data);
          _assets = (assetsRes.data as List).map((e) => Asset.fromJson(e)).toList();
          _routes = (routesRes.data as List).map((e) => SiteRoute.fromJson(e)).toList();
          _rssItems = (rssRes.data as List).map((e) => RssItem.fromJson(e)).toList();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Arcol Protocol - Guest'),
        actions: [
          TextButton(
            onPressed: () => context.go('/login'),
            child: const Text('Login'),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFocusCard(),
                    const SizedBox(height: 16),
                    _buildAssetsCard(),
                    const SizedBox(height: 16),
                    _buildRoutesCard(),
                    const SizedBox(height: 16),
                    _buildRssCard(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildFocusCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _activeSession?.isActive == true ? Icons.timer : Icons.timer_off,
                  color: _activeSession?.isActive == true ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 8),
                Text(
                  'Current Focus',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const Divider(),
            if (_activeSession?.isActive == true && _activeSession?.session != null) ...[
              Text(
                _activeSession!.session!.taskName,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              Text(
                _formatDuration(_activeSession!.session!.durationSeconds),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ] else
              const Text('Not currently tracking time'),
          ],
        ),
      ),
    );
  }

  Widget _buildAssetsCard() {
    final totalValue = _assets.fold<double>(0, (sum, a) => sum + a.totalValue);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.trending_up),
                const SizedBox(width: 8),
                Text(
                  'Digital Assets',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const Divider(),
            Text(
              'Total Value: \$${totalValue.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            if (_assets.isEmpty)
              const Text('No assets configured')
            else
              ..._assets.take(3).map((asset) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${asset.name} (${asset.symbol})'),
                    Text(
                      '\$${asset.totalValue.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: asset.profitLoss >= 0 ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              )),
          ],
        ),
      ),
    );
  }

  Widget _buildRoutesCard() {
    final activeRoutes = _routes.where((r) => r.isActive).toList();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.dns),
                const SizedBox(width: 8),
                Text(
                  'Site Routes',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const Divider(),
            Text(
              'Active: ${activeRoutes.length} / ${_routes.length}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            if (_routes.isEmpty)
              const Text('No routes configured')
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _routes.map((route) => Chip(
                  avatar: Icon(
                    route.processStatus?.isRunning == true 
                        ? Icons.check_circle 
                        : Icons.cancel,
                    color: route.processStatus?.isRunning == true 
                        ? Colors.green 
                        : Colors.red,
                    size: 18,
                  ),
                  label: Text(route.name),
                )).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRssCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.rss_feed),
                const SizedBox(width: 8),
                Text(
                  'Recent RSS',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const Divider(),
            if (_rssItems.isEmpty)
              const Text('No recent items')
            else
              ..._rssItems.map((item) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: item.aiSummary != null
                    ? Text(
                        item.aiSummary!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      )
                    : null,
              )),
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
