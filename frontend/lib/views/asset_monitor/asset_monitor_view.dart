import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/asset_provider.dart';

class AssetMonitorView extends ConsumerStatefulWidget {
  const AssetMonitorView({super.key});

  @override
  ConsumerState<AssetMonitorView> createState() => _AssetMonitorViewState();
}

class _AssetMonitorViewState extends ConsumerState<AssetMonitorView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _symbolController = TextEditingController();
  final _quantityController = TextEditingController();
  final _avgCostController = TextEditingController();
  String? _exchange;

  @override
  void dispose() {
    _nameController.dispose();
    _symbolController.dispose();
    _quantityController.dispose();
    _avgCostController.dispose();
    super.dispose();
  }

  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Asset'),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _symbolController,
                  decoration: const InputDecoration(labelText: 'Symbol'),
                  validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _exchange,
                  decoration: const InputDecoration(labelText: 'Exchange'),
                  items: ['Binance', 'Coinbase', 'Kraken', 'Other'].map((e) => 
                    DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (v) => setState(() => _exchange = v),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _quantityController,
                  decoration: const InputDecoration(labelText: 'Quantity'),
                  keyboardType: TextInputType.number,
                  validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _avgCostController,
                  decoration: const InputDecoration(labelText: 'Average Cost'),
                  keyboardType: TextInputType.number,
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
                ref.read(assetProvider.notifier).addAsset({
                  'name': _nameController.text,
                  'symbol': _symbolController.text,
                  'exchange': _exchange,
                  'quantity': double.parse(_quantityController.text),
                  'avg_cost': double.tryParse(_avgCostController.text) ?? 0,
                });
                Navigator.pop(context);
                _nameController.clear();
                _symbolController.clear();
                _quantityController.clear();
                _avgCostController.clear();
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
    final assetsAsync = ref.watch(assetProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Asset Monitor'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: () => ref.read(assetProvider.notifier).fetchAssets()),
          IconButton(icon: const Icon(Icons.add), onPressed: _showAddDialog),
        ],
      ),
      body: assetsAsync.when(
        data: (assets) {
          if (assets.isEmpty) return const Center(child: Text('No assets configured'));
          final total = assets.fold<double>(0, (sum, a) => sum + a.totalValue);
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Portfolio Value:'),
                        Text('\$${total.toStringAsFixed(2)}', style: Theme.of(context).textTheme.headlineMedium),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: assets.length,
                  itemBuilder: (context, index) {
                    final asset = assets[index];
                    return Card(
                      child: ListTile(
                        title: Text('${asset.name} (${asset.symbol})'),
                        subtitle: Text('Qty: ${asset.quantity} @ \$${asset.avgCost}'),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('\$${asset.totalValue.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text(
                              '${asset.profitLoss >= 0 ? '+' : ''}${asset.profitLossPercent.toStringAsFixed(2)}%',
                              style: TextStyle(color: asset.profitLoss >= 0 ? Colors.green : Colors.red),
                            ),
                          ],
                        ),
                        onLongPress: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Delete Asset?'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                                FilledButton(
                                  onPressed: () {
                                    ref.read(assetProvider.notifier).deleteAsset(asset.id);
                                    Navigator.pop(context);
                                  },
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
