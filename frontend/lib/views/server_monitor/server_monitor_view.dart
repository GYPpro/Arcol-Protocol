import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../providers/monitor_provider.dart';

class ServerMonitorView extends ConsumerStatefulWidget {
  const ServerMonitorView({super.key});

  @override
  ConsumerState<ServerMonitorView> createState() => _ServerMonitorViewState();
}

class _ServerMonitorViewState extends ConsumerState<ServerMonitorView> {
  Timer? _timer;
  int _hours = 24;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => ref.invalidate(serverMetricsProvider));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final metricsAsync = ref.watch(serverMetricsProvider);
    final historyAsync = ref.watch(metricsHistoryProvider(_hours));
    final thresholdsAsync = ref.watch(monitorThresholdProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Server Monitor'),
        actions: [
          DropdownButton<int>(
            value: _hours,
            items: [1, 6, 24, 72].map((h) => DropdownMenuItem(value: h, child: Text('$h hours'))).toList(),
            onChanged: (v) => setState(() => _hours = v ?? 24),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            metricsAsync.when(
              data: (metrics) => Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: _buildMetricCard('CPU', '${metrics.cpuPercent.toStringAsFixed(1)}%', Icons.memory, Colors.blue)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildMetricCard('Memory', '${metrics.memoryPercent.toStringAsFixed(1)}%', Icons.storage, Colors.purple)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _buildMetricCard('Disk', '${metrics.diskPercent.toStringAsFixed(1)}%', Icons.disc_full, Colors.orange)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildMetricCard('Network', '${(metrics.networkSentMb + metrics.networkRecvMb).toStringAsFixed(1)} MB', Icons.network_check, Colors.green)),
                    ],
                  ),
                ],
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error: $e'),
            ),
            const SizedBox(height: 24),
            Text('History', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            historyAsync.when(
              data: (history) {
                if (history.isEmpty) return const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('No history data')));
                return SizedBox(
                  height: 200,
                  child: LineChart(LineChartData(
                    gridData: const FlGridData(show: true),
                    titlesData: const FlTitlesData(show: false),
                    borderData: FlBorderData(show: true),
                    lineBarsData: [
                      LineChartBarData(
                        spots: history.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.cpuPercent)).toList(),
                        isCurved: true,
                        color: Colors.blue,
                        barWidth: 2,
                      ),
                    ],
                  )),
                );
              },
              loading: () => const SizedBox(),
              error: (e, _) => Text('Error: $e'),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Thresholds', style: Theme.of(context).textTheme.titleLarge),
                IconButton(icon: const Icon(Icons.add), onPressed: _showAddThresholdDialog),
              ],
            ),
            const SizedBox(height: 16),
            thresholdsAsync.when(
              data: (thresholds) {
                if (thresholds.isEmpty) return const Text('No thresholds configured');
                return Column(
                  children: thresholds.map((t) => Card(
                    child: ListTile(
                      leading: Icon(t.isActive ? Icons.check_circle : Icons.pause, color: t.isActive ? Colors.green : Colors.grey),
                      title: Text('${t.metricName.toUpperCase()} ${t.comparison} ${t.thresholdValue}%'),
                      trailing: IconButton(icon: const Icon(Icons.delete), onPressed: () => ref.read(monitorThresholdProvider.notifier).deleteThreshold(t.id)),
                    ),
                  )).toList(),
                );
              },
              loading: () => const CircularProgressIndicator(),
              error: (e, _) => Text('Error: $e'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(String label, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            Text(value, style: Theme.of(context).textTheme.headlineSmall),
          ],
        ),
      ),
    );
  }

  void _showAddThresholdDialog() {
    String metric = 'cpu';
    double value = 80;
    String comparison = 'gt';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Threshold'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: metric,
              items: ['cpu', 'memory', 'disk'].map((e) => DropdownMenuItem(value: e, child: Text(e.toUpperCase()))).toList(),
              onChanged: (v) => metric = v ?? 'cpu',
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: '80',
              decoration: const InputDecoration(labelText: 'Threshold Value'),
              keyboardType: TextInputType.number,
              onChanged: (v) => value = double.tryParse(v) ?? 80,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: comparison,
              items: const [DropdownMenuItem(value: 'gt', child: Text('Greater than')), DropdownMenuItem(value: 'lt', child: Text('Less than'))],
              onChanged: (v) => comparison = v ?? 'gt',
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: () { ref.read(monitorThresholdProvider.notifier).addThreshold({'metric_name': metric, 'threshold_value': value, 'comparison': comparison}); Navigator.pop(context); }, child: const Text('Add')),
        ],
      ),
    );
  }
}
