class TransactionSummary {
  final int totalTransactions;
  final int totalItemsOrdered;

  const TransactionSummary({
    required this.totalTransactions,
    required this.totalItemsOrdered,
  });

  factory TransactionSummary.fromJson(Map<String, dynamic> json) {
    return TransactionSummary(
      totalTransactions: (json['total_transactions'] as num?)?.toInt() ?? 0,
      totalItemsOrdered: (json['total_items_ordered'] as num?)?.toInt() ?? 0,
    );
  }
}