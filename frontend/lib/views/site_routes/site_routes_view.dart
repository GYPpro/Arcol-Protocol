import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../providers/site_route_provider.dart';

class SiteRoutesView extends ConsumerStatefulWidget {
  const SiteRoutesView({super.key});

  @override
  ConsumerState<SiteRoutesView> createState() => _SiteRoutesViewState();
}

class _SiteRoutesViewState extends ConsumerState<SiteRoutesView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _urlController = TextEditingController();
  final _processController = TextEditingController();
  final _dockerController = TextEditingController();
  String? _groupName;
  String? _tag;

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    _processController.dispose();
    _dockerController.dispose();
    super.dispose();
  }

  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Site Route'),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(controller: _nameController, decoration: const InputDecoration(labelText: 'Name'), validator: (v) => v?.isEmpty ?? true ? 'Required' : null),
                const SizedBox(height: 16),
                TextFormField(controller: _urlController, decoration: const InputDecoration(labelText: 'URL'), validator: (v) => v?.isEmpty ?? true ? 'Required' : null),
                const SizedBox(height: 16),
                TextFormField(controller: _processController, decoration: const InputDecoration(labelText: 'Process Name (optional)')),
                const SizedBox(height: 16),
                TextFormField(controller: _dockerController, decoration: const InputDecoration(labelText: 'Docker Container ID (optional)')),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _groupName,
                  decoration: const InputDecoration(labelText: 'Group'),
                  items: ['Main', 'Dev', 'Test', 'Other'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (v) => setState(() => _groupName = v),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                ref.read(siteRouteProvider.notifier).addRoute({
                  'name': _nameController.text,
                  'url': _urlController.text,
                  'process_name': _processController.text.isEmpty ? null : _processController.text,
                  'docker_container_id': _dockerController.text.isEmpty ? null : _dockerController.text,
                  'group_name': _groupName,
                  'sort_order': 0,
                });
                Navigator.pop(context);
                _nameController.clear();
                _urlController.clear();
                _processController.clear();
                _dockerController.clear();
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
    final routesAsync = ref.watch(siteRouteProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Site Routes'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: () => ref.read(siteRouteProvider.notifier).fetchRoutes()),
          IconButton(icon: const Icon(Icons.add), onPressed: _showAddDialog),
        ],
      ),
      body: routesAsync.when(
        data: (routes) {
          if (routes.isEmpty) return const Center(child: Text('No routes configured'));
          final groups = routes.map((r) => r.groupName).whereType<String>().toSet();
          return Column(
            children: [
              if (groups.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Wrap(spacing: 8, children: groups.map((g) => Chip(label: Text(g))).toList()),
                ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: routes.length,
                  itemBuilder: (context, index) {
                    final route = routes[index];
                    return Card(
                      child: ListTile(
                        leading: Icon(route.processStatus?.isRunning == true ? Icons.check_circle : Icons.cancel, color: route.processStatus?.isRunning == true ? Colors.green : Colors.red),
                        title: Text(route.name),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(route.url),
                            if (route.processStatus != null)
                              Text('CPU: ${route.processStatus!.cpuPercent.toStringAsFixed(1)}% | MEM: ${route.processStatus!.memoryMb.toStringAsFixed(1)} MB'),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(icon: const Icon(Icons.open_in_new), onPressed: () => launchUrl(Uri.parse(route.url))),
                            IconButton(icon: const Icon(Icons.refresh), onPressed: () => ref.read(siteRouteProvider.notifier).refreshStatus(route.id)),
                          ],
                        ),
                        onLongPress: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Delete Route?'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                                FilledButton(
                                  onPressed: () { ref.read(siteRouteProvider.notifier).deleteRoute(route.id); Navigator.pop(context); },
                                  style: FilledButton.styleFrom(backgroundColor: Colors.red),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
