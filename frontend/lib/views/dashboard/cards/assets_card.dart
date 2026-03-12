import 'package:flutter/material.dart';
import '../../../widgets/dashboard/base_card.dart';

class AssetInfo {
  final int id;
  final String name;
  final double totalValue;
  final double profitLoss;

  AssetInfo({
    required this.id,
    required this.name,
    required this.totalValue,
    required this.profitLoss,
  });
}

class AssetsCard extends StatelessWidget {
  final List<AssetInfo> assets;
  final VoidCallback? onViewAll;

  const AssetsCard({
    super.key,
    required this.assets,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    final total = assets.fold<double>(0, (sum, a) => sum + a.totalValue);

    return DashboardCard(
      title: 'Assets Overview',
      icon: Icons.trending_up,
      trailing: onViewAll != null
          ? TextButton(onPressed: onViewAll, child: const Text('View All'))
          : null,
      child: assets.isEmpty
          ? const Center(child: Text('No assets configured'))
          : Column(
              children: [
                Text(
                  '\$${total.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: assets.take(3).length,
                    itemBuilder: (context, index) {
                      final asset = assets[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(asset.name),
                        trailing: Text(
                          '\$${asset.totalValue.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: asset.profitLoss >= 0 ? Colors.green : Colors.red,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
