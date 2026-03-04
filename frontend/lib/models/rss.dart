class RssFeed {
  final int id;
  final String name;
  final String url;
  final String feedType;
  final int fetchIntervalMinutes;
  final bool aiAnalysisEnabled;
  final double importanceThreshold;
  final bool isActive;
  final DateTime? lastFetched;
  final DateTime createdAt;

  RssFeed({
    required this.id,
    required this.name,
    required this.url,
    required this.feedType,
    required this.fetchIntervalMinutes,
    required this.aiAnalysisEnabled,
    required this.importanceThreshold,
    required this.isActive,
    this.lastFetched,
    required this.createdAt,
  });

  factory RssFeed.fromJson(Map<String, dynamic> json) {
    return RssFeed(
      id: json['id'],
      name: json['name'],
      url: json['url'],
      feedType: json['feed_type'] ?? 'rss',
      fetchIntervalMinutes: json['fetch_interval_minutes'] ?? 60,
      aiAnalysisEnabled: json['ai_analysis_enabled'] ?? true,
      importanceThreshold: (json['importance_threshold'] ?? 0.7).toDouble(),
      isActive: json['is_active'] ?? true,
      lastFetched: json['last_fetched'] != null ? DateTime.parse(json['last_fetched']) : null,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'url': url,
      'feed_type': feedType,
      'fetch_interval_minutes': fetchIntervalMinutes,
      'ai_analysis_enabled': aiAnalysisEnabled,
      'importance_threshold': importanceThreshold,
      'is_active': isActive,
    };
  }
}

class RssItem {
  final int id;
  final int feedId;
  final String title;
  final String? link;
  final String? description;
  final String? content;
  final String? author;
  final DateTime? publishedAt;
  final String? guid;
  final String? aiSummary;
  final String? aiCategory;
  final double? aiImportance;
  final bool pushedToQueue;
  final DateTime createdAt;

  RssItem({
    required this.id,
    required this.feedId,
    required this.title,
    this.link,
    this.description,
    this.content,
    this.author,
    this.publishedAt,
    this.guid,
    this.aiSummary,
    this.aiCategory,
    this.aiImportance,
    required this.pushedToQueue,
    required this.createdAt,
  });

  factory RssItem.fromJson(Map<String, dynamic> json) {
    return RssItem(
      id: json['id'],
      feedId: json['feed_id'],
      title: json['title'],
      link: json['link'],
      description: json['description'],
      content: json['content'],
      author: json['author'],
      publishedAt: json['published_at'] != null ? DateTime.parse(json['published_at']) : null,
      guid: json['guid'],
      aiSummary: json['ai_summary'],
      aiCategory: json['ai_category'],
      aiImportance: json['ai_importance']?.toDouble(),
      pushedToQueue: json['pushed_to_queue'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
