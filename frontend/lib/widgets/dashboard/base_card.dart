import 'package:flutter/material.dart';

class DashboardCard extends StatelessWidget {
  final String title;
  final IconData? icon;
  final Widget child;
  final Widget? trailing;
  final Color? iconColor;
  final EdgeInsets? padding;
  final String? cardId;

  const DashboardCard({
    super.key,
    required this.title,
    this.icon,
    required this.child,
    this.trailing,
    this.iconColor,
    this.padding,
    this.cardId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          if (title.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
              child: Row(
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 18, color: iconColor ?? theme.colorScheme.primary),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (trailing != null) trailing!,
                ],
              ),
            ),
          const Divider(height: 1),
          // Content
          Flexible(
            child: Padding(
              padding: padding ?? const EdgeInsets.all(16),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

class CardSize {
  final double widthFactor;
  final double height;

  const CardSize({
    this.widthFactor = 1.0,
    this.height = 200,
  });

  Map<String, dynamic> toJson() => {
    'widthFactor': widthFactor,
    'height': height,
  };

  factory CardSize.fromJson(Map<String, dynamic> json) => CardSize(
    widthFactor: (json['widthFactor'] ?? 1.0).toDouble(),
    height: (json['height'] ?? 200).toDouble(),
  );
}

class CardPosition {
  final String cardId;
  final int column;
  final int order;

  const CardPosition({
    required this.cardId,
    required this.column,
    required this.order,
  });

  Map<String, dynamic> toJson() => {
    'cardId': cardId,
    'column': column,
    'order': order,
  };

  factory CardPosition.fromJson(Map<String, dynamic> json) => CardPosition(
    cardId: json['cardId'],
    column: json['column'],
    order: json['order'],
  );
}
