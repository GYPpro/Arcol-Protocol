class Asset {
  final int id;
  final String name;
  final String symbol;
  final String? exchange;
  final double quantity;
  final double avgCost;
  final double? currentPrice;
  final DateTime? lastUpdated;
  final DateTime createdAt;
  final double totalValue;
  final double profitLoss;
  final double profitLossPercent;

  Asset({
    required this.id,
    required this.name,
    required this.symbol,
    this.exchange,
    required this.quantity,
    required this.avgCost,
    this.currentPrice,
    this.lastUpdated,
    required this.createdAt,
    this.totalValue = 0,
    this.profitLoss = 0,
    this.profitLossPercent = 0,
  });

  factory Asset.fromJson(Map<String, dynamic> json) {
    return Asset(
      id: json['id'],
      name: json['name'],
      symbol: json['symbol'],
      exchange: json['exchange'],
      quantity: (json['quantity'] ?? 0).toDouble(),
      avgCost: (json['avg_cost'] ?? 0).toDouble(),
      currentPrice: json['current_price']?.toDouble(),
      lastUpdated: json['last_updated'] != null ? DateTime.parse(json['last_updated']) : null,
      createdAt: DateTime.parse(json['created_at']),
      totalValue: (json['total_value'] ?? 0).toDouble(),
      profitLoss: (json['profit_loss'] ?? 0).toDouble(),
      profitLossPercent: (json['profit_loss_percent'] ?? 0).toDouble(),
    );
  }
}
