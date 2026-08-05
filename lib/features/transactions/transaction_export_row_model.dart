class TransactionExportItem {
  final String productId;
  final String productName;
  final int qty;
  final num price;

  const TransactionExportItem({
    required this.productId,
    required this.productName,
    required this.qty,
    required this.price,
  });

  factory TransactionExportItem.fromJson(Map<String, dynamic> json) {
    return TransactionExportItem(
      productId: json['product_id'] as String? ?? '',
      productName: json['product_name'] as String? ?? '-',
      qty: (json['qty'] as num?)?.toInt() ?? 0,
      price: num.tryParse(json['price'].toString()) ?? 0,
    );
  }
}

class TransactionExportRow {
  final String id;
  final String invoiceNumber;
  final String status;
  final num subtotal;
  final num grandTotal;
  final List<TransactionExportItem> items;

  const TransactionExportRow({
    required this.id,
    required this.invoiceNumber,
    required this.status,
    required this.subtotal,
    required this.grandTotal,
    required this.items,
  });

  int get totalQty => items.fold(0, (sum, i) => sum + i.qty);

  factory TransactionExportRow.fromJson(Map<String, dynamic> json) {
    return TransactionExportRow(
      id: json['id'] as String? ?? '',
      invoiceNumber: json['invoice_number'] as String? ?? '',
      status: json['status'] as String? ?? '',
      subtotal: num.tryParse(json['subtotal'].toString()) ?? 0,
      grandTotal: num.tryParse(json['grand_total'].toString()) ?? 0,
      items: (json['items'] as List<dynamic>? ?? [])
          .map((e) => TransactionExportItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class TransactionExportPage {
  final List<TransactionExportRow> data;
  final int total;
  final int offset;
  final int limit;
  final bool hasMore;

  const TransactionExportPage({
    required this.data,
    required this.total,
    required this.offset,
    required this.limit,
    required this.hasMore,
  });

  factory TransactionExportPage.fromJson(Map<String, dynamic> json) {
    final meta = json['meta'] as Map<String, dynamic>? ?? {};
    return TransactionExportPage(
      data: (json['data'] as List<dynamic>? ?? [])
          .map((e) => TransactionExportRow.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: (meta['total'] as num?)?.toInt() ?? 0,
      offset: (meta['offset'] as num?)?.toInt() ?? 0,
      limit: (meta['limit'] as num?)?.toInt() ?? 0,
      hasMore: meta['has_more'] as bool? ?? false,
    );
  }
}