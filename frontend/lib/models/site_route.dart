class SiteRoute {
  final int id;
  final String name;
  final String url;
  final String? groupName;
  final String? tag;
  final String? processName;
  final String? dockerContainerId;
  final int sortOrder;
  final bool isActive;
  final DateTime createdAt;
  final ProcessStatus? processStatus;

  SiteRoute({
    required this.id,
    required this.name,
    required this.url,
    this.groupName,
    this.tag,
    this.processName,
    this.dockerContainerId,
    required this.sortOrder,
    required this.isActive,
    required this.createdAt,
    this.processStatus,
  });

  factory SiteRoute.fromJson(Map<String, dynamic> json) {
    return SiteRoute(
      id: json['id'],
      name: json['name'],
      url: json['url'],
      groupName: json['group_name'],
      tag: json['tag'],
      processName: json['process_name'],
      dockerContainerId: json['docker_container_id'],
      sortOrder: json['sort_order'] ?? 0,
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
      processStatus: json['process_status'] != null 
          ? ProcessStatus.fromJson(json['process_status']) 
          : null,
    );
  }
}

class ProcessStatus {
  final int id;
  final bool isRunning;
  final double cpuPercent;
  final double memoryPercent;
  final double memoryMb;
  final String status;
  final DateTime lastCheck;
  final String? errorMessage;

  ProcessStatus({
    required this.id,
    required this.isRunning,
    required this.cpuPercent,
    required this.memoryPercent,
    required this.memoryMb,
    required this.status,
    required this.lastCheck,
    this.errorMessage,
  });

  factory ProcessStatus.fromJson(Map<String, dynamic> json) {
    return ProcessStatus(
      id: json['id'],
      isRunning: json['is_running'] ?? false,
      cpuPercent: (json['cpu_percent'] ?? 0).toDouble(),
      memoryPercent: (json['memory_percent'] ?? 0).toDouble(),
      memoryMb: (json['memory_mb'] ?? 0).toDouble(),
      status: json['status'] ?? 'unknown',
      lastCheck: DateTime.parse(json['last_check']),
      errorMessage: json['error_message'],
    );
  }
}
