import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:senkukoadmin/constant/app_colors.dart';
import 'package:senkukoadmin/constant/currency_formatter.dart';

// ── List response parser ──────────────────────────────────────────────────────

TransactionModel transactionModelFromJson(String str) =>
    TransactionModel.fromJson(json.decode(str));

class TransactionModel {
  final bool success;
  final List<TransactionData> data;

  TransactionModel({required this.success, required this.data});

  factory TransactionModel.fromJson(Map<String, dynamic> json) =>
      TransactionModel(
        success: json['success'],
        data: List<TransactionData>.from(
          json['data'].map((x) => TransactionData.fromJson(x)),
        ),
      );
}

// ── Payment style ─────────────────────────────────────────────────────────────

class PaymentStyle {
  final Color color;
  final Color background;
  final IconData icon;
  final String label;

  const PaymentStyle({
    required this.color,
    required this.background,
    required this.icon,
    required this.label,
  });

  static PaymentStyle of(String method) {
    switch (method) {
      case 'cash':
      case 'cod':
        return const PaymentStyle(
          color: AppColors.primary,
          background: Color(0xFFE8FAF3),
          icon: Icons.payments_outlined,
          label: 'Tunai / COD',
        );
      case 'transfer':
      case 'bank_transfer':
        return const PaymentStyle(
          color: AppColors.secondary,
          background: Color(0xFFEEF3FF),
          icon: Icons.account_balance_outlined,
          label: 'Transfer Bank',
        );
      case 'qris':
        return const PaymentStyle(
          color: Color(0xFF9B6DFF),
          background: Color(0xFFF3EEFF),
          icon: Icons.qr_code_outlined,
          label: 'QRIS',
        );
      case 'gopay':
        return const PaymentStyle(
          color: Color(0xFF00AED6),
          background: Color(0xFFE5F7FB),
          icon: Icons.account_balance_wallet_outlined,
          label: 'GoPay',
        );
      case 'shopeepay':
        return const PaymentStyle(
          color: Color(0xFFEE4D2D),
          background: Color(0xFFFEEDE9),
          icon: Icons.account_balance_wallet_outlined,
          label: 'ShopeePay',
        );
      default:
        return PaymentStyle(
          color: Colors.grey,
          background: Colors.grey.shade100,
          icon: Icons.payment_outlined,
          label: method,
        );
    }
  }
}

// ── Transaction status style ──────────────────────────────────────────────────

class StatusStyle {
  final Color color;
  final Color background;
  final String label;

  const StatusStyle({
    required this.color,
    required this.background,
    required this.label,
  });

  static StatusStyle of(String status) {
    switch (status) {
      case 'pending_payment':
        return const StatusStyle(
          color: Color(0xFFF59E0B),
          background: Color(0xFFFEF3C7),
          label: 'Menunggu Bayar',
        );
      case 'processing':
        return const StatusStyle(
          color: Color(0xFF3B82F6),
          background: Color(0xFFEFF6FF),
          label: 'Diproses',
        );
      case 'shipped':
        return const StatusStyle(
          color: Color(0xFF8B5CF6),
          background: Color(0xFFF5F3FF),
          label: 'Dikirim',
        );
      case 'completed':
        return const StatusStyle(
          color: AppColors.primary,
          background: Color(0xFFE8FAF3),
          label: 'Selesai',
        );
      case 'cancelled':
        return const StatusStyle(
          color: Color(0xFF6B7280),
          background: Color(0xFFF3F4F6),
          label: 'Dibatalkan',
        );
      case 'failed':
        return const StatusStyle(
          color: Color(0xFFEF4444),
          background: Color(0xFFFEE2E2),
          label: 'Gagal',
        );
      default:
        return StatusStyle(
          color: Colors.grey,
          background: Colors.grey.shade100,
          label: status,
        );
    }
  }
}

// ── TransactionData — dipakai di list page ────────────────────────────────────

class TransactionData {
  final String id;
  final String invoiceNumber;
  final String status;
  final String paymentStatus;
  final double subtotal;
  final double totalDiscount;
  final double grandTotal;
  final double paidAmount;
  final double changeAmount;
  final String paymentMethod;
  final String? deliveryAddress;
  final String? deliveryCity;
  final String? deliveryRegion;
  final String? deliverySubregion;
  final String? deliveryNote;
  final DateTime transactedAt;
  final DateTime createdAt;
  final String? customerName;

  TransactionData({
    required this.id,
    required this.invoiceNumber,
    required this.status,
    required this.paymentStatus,
    required this.subtotal,
    required this.totalDiscount,
    required this.grandTotal,
    required this.paidAmount,
    required this.changeAmount,
    required this.paymentMethod,
    this.deliveryAddress,
    this.deliveryCity,
    this.deliveryRegion,
    this.deliverySubregion,
    this.deliveryNote,
    required this.transactedAt,
    required this.createdAt,
    this.customerName,
  });

  factory TransactionData.fromJson(Map<String, dynamic> json) =>
      TransactionData(
        id: json['id'],
        invoiceNumber: json['invoice_number'],
        status: json['status'],
        paymentStatus: json['payment_status'] ?? 'pending',
        subtotal: double.parse(json['subtotal'].toString()),
        totalDiscount: double.parse(json['total_discount'].toString()),
        grandTotal: double.parse(json['grand_total'].toString()),
        paidAmount: double.parse((json['paid_amount'] ?? '0').toString()),
        changeAmount: double.parse((json['change_amount'] ?? '0').toString()),
        paymentMethod: json['payment_method'],
        deliveryAddress: json['delivery_address'],
        deliveryCity: json['delivery_city'],
        deliveryRegion: json['delivery_region'],
        deliverySubregion: json['delivery_subregion'],
        deliveryNote: json['delivery_note'],
        transactedAt: DateTime.parse(json['transacted_at']).toLocal(),
        createdAt: DateTime.parse(json['created_at']).toLocal(),
        customerName: json['customer_name'],
      );

  // ── Computed ──────────────────────────────────────────────────────────────
  PaymentStyle get paymentStyle => PaymentStyle.of(paymentMethod);
  StatusStyle get statusStyle => StatusStyle.of(status);
  String get paymentMethodLabel => paymentStyle.label;

  /// Hanya status yang relevan secara bisnis yang dihitung sebagai revenue.
  bool get isCountableRevenue =>
      status == 'completed' ||
      status == 'processing' ||
      status == 'shipped';

  // ── Formatters ────────────────────────────────────────────────────────────
  String get formattedGrandTotal => CurrencyFormatter.format(grandTotal);
  String get formattedSubtotal => CurrencyFormatter.format(subtotal);
  String get formattedPaidAmount => CurrencyFormatter.format(paidAmount);
  String get formattedChangeAmount => CurrencyFormatter.format(changeAmount);
  String get formattedTotalDiscount => CurrencyFormatter.format(totalDiscount);
}

// ── TransactionItem — item dalam detail transaksi ─────────────────────────────

class TransactionItem {
  final String id;
  final String productVariantId;
  final String variantName;
  final String priceListName;
  final int qty;
  final double unitPrice;
  final double originalPrice;
  final double discountAmount;
  final double subtotal;

  TransactionItem({
    required this.id,
    required this.productVariantId,
    required this.variantName,
    required this.priceListName,
    required this.qty,
    required this.unitPrice,
    required this.originalPrice,
    required this.discountAmount,
    required this.subtotal,
  });

  factory TransactionItem.fromJson(Map<String, dynamic> json) =>
      TransactionItem(
        id: json['id'],
        productVariantId: json['product_variant_id'],
        variantName: json['variant_name'],
        priceListName: json['price_list_name'],
        qty: json['qty'] is int
            ? json['qty']
            : int.parse(json['qty'].toString()),
        unitPrice: double.parse(json['unit_price'].toString()),
        originalPrice: double.parse(json['original_price'].toString()),
        discountAmount: double.parse(
          (json['discount_amount'] ?? '0').toString(),
        ),
        subtotal: double.parse(json['subtotal'].toString()),
      );

  String get formattedUnitPrice => CurrencyFormatter.format(unitPrice);
  String get formattedSubtotal => CurrencyFormatter.format(subtotal);
}

// ── TransactionPromotion — promo yang diterapkan ─────────────────────────────

class TransactionPromotion {
  final String id;
  final String? promotionName;
  final String? promotionCode;
  final String? voucherCode;
  final double discountGiven;

  TransactionPromotion({
    required this.id,
    this.promotionName,
    this.promotionCode,
    this.voucherCode,
    required this.discountGiven,
  });

  factory TransactionPromotion.fromJson(Map<String, dynamic> json) =>
      TransactionPromotion(
        id: json['id'],
        promotionName: json['promotion_name'],
        promotionCode: json['promotion_code'],
        voucherCode: json['voucher_code'],
        discountGiven: double.parse(
          (json['discount_given'] ?? '0').toString(),
        ),
      );

  /// Label yang ditampilkan di UI — nama promo atau kode voucher.
  String get displayLabel =>
      promotionName ?? voucherCode ?? promotionCode ?? '-';

  String get formattedDiscount => CurrencyFormatter.format(discountGiven);
}

// ── TransactionDetail — response GET /transactions/:id ───────────────────────

class TransactionDetail {
  final String id;
  final String invoiceNumber;
  final String status;
  final String paymentStatus;
  final double subtotal;
  final double totalDiscount;
  final double grandTotal;
  final double paidAmount;
  final double changeAmount;
  final String paymentMethod;
  final String? midtransOrderId;
  final String? midtransToken;
  final String? midtransPdfUrl;
  final DateTime? paidAt;
  final String? deliveryAddress;
  final String? deliveryCity;
  final String? deliveryRegion;
  final String? deliverySubregion;
  final String? deliveryNote;
  final String? customerName;
  final DateTime transactedAt;
  final List<TransactionItem> items;
  final List<TransactionPromotion> promotions;

  TransactionDetail({
    required this.id,
    required this.invoiceNumber,
    required this.status,
    required this.paymentStatus,
    required this.subtotal,
    required this.totalDiscount,
    required this.grandTotal,
    required this.paidAmount,
    required this.changeAmount,
    required this.paymentMethod,
    this.midtransOrderId,
    this.midtransToken,
    this.midtransPdfUrl,
    this.paidAt,
    this.deliveryAddress,
    this.deliveryCity,
    this.deliveryRegion,
    this.deliverySubregion,
    this.deliveryNote,
    this.customerName,
    required this.transactedAt,
    required this.items,
    required this.promotions,
  });

  factory TransactionDetail.fromJson(Map<String, dynamic> json) =>
      TransactionDetail(
        id: json['id'],
        invoiceNumber: json['invoice_number'],
        status: json['status'],
        paymentStatus: json['payment_status'] ?? 'pending',
        subtotal: double.parse(json['subtotal'].toString()),
        totalDiscount: double.parse(json['total_discount'].toString()),
        grandTotal: double.parse(json['grand_total'].toString()),
        paidAmount: double.parse((json['paid_amount'] ?? '0').toString()),
        changeAmount: double.parse((json['change_amount'] ?? '0').toString()),
        paymentMethod: json['payment_method'],
        midtransOrderId: json['midtrans_order_id'],
        midtransToken: json['midtrans_token'],
        midtransPdfUrl: json['midtrans_pdf_url'],
        paidAt: json['paid_at'] != null
            ? DateTime.parse(json['paid_at']).toLocal()
            : null,
        deliveryAddress: json['delivery_address'],
        deliveryCity: json['delivery_city'],
        deliveryRegion: json['delivery_region'],
        deliverySubregion: json['delivery_subregion'],
        deliveryNote: json['delivery_note'],
        customerName: json['customer_name'],
        transactedAt: DateTime.parse(json['transacted_at']).toLocal(),
        items: (json['items'] as List? ?? [])
            .map((e) => TransactionItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        promotions: (json['promotions'] as List? ?? [])
            .map(
              (e) =>
                  TransactionPromotion.fromJson(e as Map<String, dynamic>),
            )
            .toList(),
      );

  // ── Computed ──────────────────────────────────────────────────────────────
  PaymentStyle get paymentStyle => PaymentStyle.of(paymentMethod);
  StatusStyle get statusStyle => StatusStyle.of(status);
  String get paymentMethodLabel => paymentStyle.label;
  bool get isCod => paymentMethod == 'cod';
  bool get hasAddress => deliveryAddress != null;

  /// Bagian alamat baris kedua: subregion, region, city
  String get addressLine2 => [
        deliverySubregion,
        deliveryRegion,
        deliveryCity,
      ].whereType<String>().join(', ');

  // ── Formatters ────────────────────────────────────────────────────────────
  String get formattedGrandTotal => CurrencyFormatter.format(grandTotal);
  String get formattedSubtotal => CurrencyFormatter.format(subtotal);
  String get formattedPaidAmount => CurrencyFormatter.format(paidAmount);
  String get formattedChangeAmount => CurrencyFormatter.format(changeAmount);
  String get formattedTotalDiscount => CurrencyFormatter.format(totalDiscount);
}