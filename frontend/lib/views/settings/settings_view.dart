import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api_client.dart';
import '../../providers/auth_provider.dart';

class SettingsView extends ConsumerStatefulWidget {
  const SettingsView({super.key});

  @override
  ConsumerState<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends ConsumerState<SettingsView> {
  List<dynamic> _apiKeys = [];
  List<dynamic> _queueConfigs = [];
  bool _loading = true;
  final _keyNameController = TextEditingController();
  final _keyProviderController = TextEditingController();
  final _queueNameController = TextEditingController();
  final _queueHostController = TextEditingController();
  final _queuePortController = TextEditingController(text: '6379');
  final _queueDbController = TextEditingController(text: '0');
  final _queuePasswordController = TextEditingController();
  final _queueConsumerController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void dispose() {
    _keyNameController.dispose();
    _keyProviderController.dispose();
    _queueNameController.dispose();
    _queueHostController.dispose();
    _queuePortController.dispose();
    _queueDbController.dispose();
    _queuePasswordController.dispose();
    _queueConsumerController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    try {
      final dio = ref.read(dioProvider);
      final keysRes = await dio.get('/settings/api-keys');
      final queueRes = await dio.get('/settings/queue-configs');
      setState(() {
        _apiKeys = keysRes.data;
        _queueConfigs = queueRes.data;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  void _showAddKeyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add API Key'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _keyNameController, decoration: const InputDecoration(labelText: 'Name')),
            const SizedBox(height: 16),
            TextField(controller: _keyProviderController, decoration: const InputDecoration(labelText: 'Provider (e.g., OpenAI)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              if (_keyNameController.text.isNotEmpty) {
                final dio = ref.read(dioProvider);
                await dio.post('/settings/api-keys', data: {'name': _keyNameController.text, 'provider': _keyProviderController.text});
                Navigator.pop(context);
                _keyNameController.clear();
                _keyProviderController.clear();
                _fetchData();
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showAddQueueDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Queue Config'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: _queueNameController, decoration: const InputDecoration(labelText: 'Name')),
              const SizedBox(height: 16),
              TextField(controller: _queueHostController, decoration: const InputDecoration(labelText: 'Redis Host')),
              const SizedBox(height: 16),
              TextField(controller: _queuePortController, decoration: const InputDecoration(labelText: 'Port'), keyboardType: TextInputType.number),
              const SizedBox(height: 16),
              TextField(controller: _queueDbController, decoration: const InputDecoration(labelText: 'DB'), keyboardType: TextInputType.number),
              const SizedBox(height: 16),
              TextField(controller: _queuePasswordController, decoration: const InputDecoration(labelText: 'Password (optional)')),
              const SizedBox(height: 16),
              TextField(controller: _queueConsumerController, decoration: const InputDecoration(labelText: 'Consumer Process (optional)')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              if (_queueNameController.text.isNotEmpty) {
                final dio = ref.read(dioProvider);
                await dio.post('/settings/queue-configs', data: {
                  'name': _queueNameController.text,
                  'redis_host': _queueHostController.text,
                  'redis_port': int.tryParse(_queuePortController.text) ?? 6379,
                  'redis_db': int.tryParse(_queueDbController.text) ?? 0,
                  'redis_password': _queuePasswordController.text.isEmpty ? null : _queuePasswordController.text,
                  'consumer_process': _queueConsumerController.text.isEmpty ? null : _queueConsumerController.text,
                  'queue_name': 'default',
                });
                Navigator.pop(context);
                _queueNameController.clear();
                _queuePasswordController.clear();
                _queueConsumerController.clear();
                _fetchData();
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
    final authState = ref.watch(authProvider);

    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('User Profile', style: Theme.of(context).textTheme.titleMedium),
                    const Divider(),
                    Text('Username: ${authState.user?.username ?? "N/A"}'),
                    Text('Email: ${authState.user?.email ?? "N/A"}'),
                    Text('Created: ${authState.user?.createdAt ?? "N/A"}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('API Keys', style: Theme.of(context).textTheme.titleMedium),
                        IconButton(icon: const Icon(Icons.add), onPressed: _showAddKeyDialog),
                      ],
                    ),
                    const Divider(),
                    if (_apiKeys.isEmpty) const Text('No API keys configured')
                    else
                      ..._apiKeys.map((key) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(key['name']),
                        subtitle: Text(key['provider'] ?? 'Unknown'),
                        trailing: IconButton(icon: const Icon(Icons.delete), onPressed: () async {
                          final dio = ref.read(dioProvider);
                          await dio.delete('/settings/api-keys/${key['id']}');
                          _fetchData();
                        }),
                      )),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Redis Queue Configs', style: Theme.of(context).textTheme.titleMedium),
                        IconButton(icon: const Icon(Icons.add), onPressed: _showAddQueueDialog),
                      ],
                    ),
                    const Divider(),
                    if (_queueConfigs.isEmpty) const Text('No queue configs configured')
                    else
                      ..._queueConfigs.map((config) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(config['name']),
                        subtitle: Text('${config['redis_host']}:${config['redis_port']}/${config['redis_db']}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(config['is_active'] ? 'Active' : 'Inactive'),
                            IconButton(icon: const Icon(Icons.delete), onPressed: () async {
                              final dio = ref.read(dioProvider);
                              await dio.delete('/settings/queue-configs/${config['id']}');
                              _fetchData();
                            }),
                          ],
                        ),
                      )),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
