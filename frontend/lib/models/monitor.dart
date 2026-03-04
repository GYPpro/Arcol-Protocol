class ServerMetrics {
  final int id;
  final double cpuPercent;
  final double memoryPercent;
  final double memoryUsedMb;
  final double memoryTotalMb;
  final double diskPercent;
  final double diskUsedGb;
  final double diskTotalGb;
  final double networkSentMb;
  final double networkRecvMb;
  final DateTime timestamp;

  ServerMetrics({
    required this.id,
    required this.cpuPercent,
    required this.memoryPercent,
    required this.memoryUsedMb,
    required this.memoryTotalMb,
    required this.diskPercent,
    required this.diskUsedGb,
    required this.diskTotalGb,
    required this.networkSentMb,
    required this.networkRecvMb,
    required this.timestamp,
  });

  factory ServerMetrics.fromJson(Map<String, dynamic> json) {
    return ServerMetrics(
      id: json['id'],
      cpuPercent: (json['cpu_percent'] ?? 0).toDouble(),
      memoryPercent: (json['memory_percent'] ?? 0).toDouble(),
      memoryUsedMb: (json['memory_used_mb'] ?? 0).toDouble(),
      memoryTotalMb: (json['memory_total_mb'] ?? 0).toDouble(),
      diskPercent: (json['disk_percent'] ?? 0).toDouble(),
      diskUsedGb: (json['disk_used_gb'] ?? 0).toDouble(),
      diskTotalGb: (json['disk_total_gb'] ?? 0).toDouble(),
      networkSentMb: (json['network_sent_mb'] ?? 0).toDouble(),
      networkRecvMb: (json['network_recv_mb'] ?? 0).toDouble(),
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}

class MonitorThreshold {
  final int id;
  final String metricName;
  final double thresholdValue;
  final String comparison;
  final bool isActive;
  final DateTime createdAt;

  MonitorThreshold({
    required this.id,
    required this.metricName,
    required this.thresholdValue,
    required this.comparison,
    required this.isActive,
    required this.createdAt,
  });

  factory MonitorThreshold.fromJson(Map<String, dynamic> json) {
    return MonitorThreshold(
      id: json['id'],
      metricName: json['metric_name'],
      thresholdValue: (json['threshold_value'] ?? 0).toDouble(),
      comparison: json['comparison'] ?? 'gt',
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'metric_name': metricName,
      'threshold_value': thresholdValue,
      'comparison': comparison,
      'is_active': isActive,
    };
  }
}
