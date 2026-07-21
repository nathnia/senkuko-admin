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

  static PaymentStyle of(String? method) {
    switch (method) {
      case null:
        // Belum ada metode pembayaran — misal transaksi pending/cancelled
        // yang belum sempat dibayar.
        return const PaymentStyle(
          color: AppColors.subtext,
          background: AppColors.neutralBg,
          icon: Icons.remove_circle_outline,
          label: 'Belum Dibayar',
        );
      case 'cash':
      case 'cod':
        return const PaymentStyle(
          color: AppColors.success,
          background: AppColors.successBg,
          icon: Icons.payments_outlined,
          label: 'Tunai / COD',
        );
      case 'transfer':
      case 'bank_transfer':
        return const PaymentStyle(
          color: AppColors.secondary,
          background: AppColors.secondaryBg,
          icon: Icons.account_balance_outlined,
          label: 'Transfer Bank',
        );
      case 'qris':
        // Brand color QRIS — tidak ada padanannya di AppColors
        return const PaymentStyle(
          color: Color(0xFF9B6DFF),
          background: Color(0xFFF3EEFF),
          icon: Icons.qr_code_outlined,
          label: 'QRIS',
        );
      case 'gopay':
        // Brand color GoPay
        return const PaymentStyle(
          color: Color(0xFF00AED6),
          background: Color(0xFFE5F7FB),
          icon: Icons.account_balance_wallet_outlined,
          label: 'GoPay',
        );
      case 'shopeepay':
        // Brand color ShopeePay
        return const PaymentStyle(
          color: Color(0xFFEE4D2D),
          background: Color(0xFFFEEDE9),
          icon: Icons.account_balance_wallet_outlined,
          label: 'ShopeePay',
        );
      default:
        return const PaymentStyle(
          color: AppColors.subtext,
          background: AppColors.neutralBg,
          icon: Icons.payment_outlined,
          label: 'Lainnya',
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
          color: AppColors.warning,
          background: AppColors.warningBg,
          label: 'Konfirmasi COD',
        );
      case 'processing':
        return const StatusStyle(
          color: AppColors.secondary,
          background: AppColors.secondaryBg,
          label: 'Perlu Dikemas', // ← was 'Diproses'
        );
      case 'shipped':
        return const StatusStyle(
          color: AppColors.shipped,
          background: AppColors.shippedBg,
          label: 'Dikirim',
        );
      case 'completed':
        return const StatusStyle(
          color: AppColors.success,
          background: AppColors.successBg,
          label: 'Selesai',
        );
      case 'cancelled':
        return const StatusStyle(
          color: AppColors.subtext,
          background: AppColors.neutralBg,
          label: 'Dibatalkan',
        );
      case 'failed':
        return const StatusStyle(
          color: AppColors.danger,
          background: AppColors.dangerBg,
          label: 'Gagal',
        );
      default:
        return const StatusStyle(
          color: AppColors.subtext,
          background: AppColors.neutralBg,
          label: 'Unknown',
        );
    }
  }
}

// ── TransactionData — dipakai di list page ────────────────────────────────────

class TransactionData {
  final String id;
  final String invoiceNumber;
  final String status;

  // Parsed from API but intentionally not displayed in admin UI.
  // Admin only needs transaction status, not payment gateway status.
  final String paymentStatus;

  final double subtotal;
  final double totalDiscount;
  final double grandTotal;
  final double paidAmount;
  final double changeAmount;
  final String? paymentMethod;
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
    this.paymentMethod,
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
  bool get isCod => paymentMethod == 'cod' || paymentMethod == 'cash';

  /// Hanya status yang relevan secara bisnis yang dihitung sebagai revenue.
  bool get isCountableRevenue =>
      status == 'completed' || status == 'processing' || status == 'shipped';

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

  factory TransactionItem.fromJson(
    Map<String, dynamic> json,
  ) => TransactionItem(
    id: json['id'],
    productVariantId: json['product_variant_id'],
    variantName: json['variant_name'],
    priceListName: json['price_list_name'],
    qty: json['qty'] is int ? json['qty'] : int.parse(json['qty'].toString()),
    unitPrice: double.parse(json['unit_price'].toString()),
    originalPrice: double.parse(json['original_price'].toString()),
    discountAmount: double.parse((json['discount_amount'] ?? '0').toString()),
    subtotal: double.parse(json['subtotal'].toString()),
  );

  String get formattedUnitPrice => CurrencyFormatter.format(unitPrice);
  String get formattedSubtotal => CurrencyFormatter.format(subtotal);
}

// ── TransactionFreeItem — item gratis yang didapat dari reward free_item ──────

class TransactionFreeItem {
  final String id;
  final String transactionPromotionId;
  final String productVariantId;
  final String variantName;
  final int qty;
  final double unitPrice;

  TransactionFreeItem({
    required this.id,
    required this.transactionPromotionId,
    required this.productVariantId,
    required this.variantName,
    required this.qty,
    required this.unitPrice,
  });

  factory TransactionFreeItem.fromJson(Map<String, dynamic> json) =>
      TransactionFreeItem(
        id: json['id'],
        transactionPromotionId: json['transaction_promotion_id'],
        productVariantId: json['product_variant_id'],
        variantName: json['variant_name'],
        qty: json['qty'] is int
            ? json['qty']
            : int.parse(json['qty'].toString()),
        unitPrice: double.parse(json['unit_price'].toString()),
      );

  String get formattedUnitPrice => CurrencyFormatter.format(unitPrice);
}

// ── AppliedReward — detail reward yang dipakai (dari kolom applied_rewards) ───

class AppliedReward {
  final String rewardType;
  final double? discountValue;
  final String? discountMode;

  AppliedReward({
    required this.rewardType,
    this.discountValue,
    this.discountMode,
  });

  factory AppliedReward.fromJson(Map<String, dynamic> json) => AppliedReward(
        rewardType: json['reward_type'] ?? '',
        discountValue: json['discount_value'] != null
            ? double.tryParse(json['discount_value'].toString())
            : null,
        discountMode: json['discount_mode'],
      );

  String get modeLabel =>
      discountMode == 'per_item' ? 'Per Item' : 'Per Transaksi';

  /// Deskripsi singkat reward — dipakai buat nampilin value promo ke admin.
  String get description {
    switch (rewardType) {
      case 'discount_percent':
        final val = discountValue?.toStringAsFixed(0) ?? '0';
        return 'Diskon $val% • $modeLabel';
      case 'discount_fixed':
        return 'Potongan ${CurrencyFormatter.format(discountValue ?? 0)} • $modeLabel';
      case 'free_item':
        return 'Reward Gratis Item';
      default:
        return rewardType;
    }
  }
}

// ── TransactionPromotion — promo yang diterapkan ─────────────────────────────

class TransactionPromotion {
  final String id;
  final String? promotionName;
  final String? promotionCode;
  final String? voucherCode;
  final double discountGiven;
  final List<TransactionFreeItem> freeItems;
  final List<AppliedReward> appliedRewards;

  TransactionPromotion({
    required this.id,
    this.promotionName,
    this.promotionCode,
    this.voucherCode,
    required this.discountGiven,
    this.freeItems = const [],
    this.appliedRewards = const [],
  });

  factory TransactionPromotion.fromJson(Map<String, dynamic> json) =>
      TransactionPromotion(
        id: json['id'],
        promotionName: json['promotion_name'],
        promotionCode: json['promotion_code'],
        voucherCode: json['voucher_code'],
        discountGiven: double.parse((json['discount_given'] ?? '0').toString()),
        freeItems: (json['free_items'] as List<dynamic>? ?? [])
            .map((e) => TransactionFreeItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        appliedRewards: _parseAppliedRewards(json['applied_rewards']),
      );

  /// applied_rewards dikirim backend sebagai JSON *string* (bukan array
  /// langsung), jadi perlu di-decode dulu. Dibungkus try-catch biar kalau
  /// formatnya berubah/null, UI tetap jalan tanpa crash.
  static List<AppliedReward> _parseAppliedRewards(dynamic raw) {
    if (raw == null) return [];
    try {
      final decoded = raw is String ? jsonDecode(raw) : raw;
      if (decoded is! List) return [];
      return decoded
          .map((e) => AppliedReward.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Label yang ditampilkan di UI — nama promo atau kode voucher.
  String get displayLabel =>
      promotionName ?? voucherCode ?? promotionCode ?? '-';

  /// Gabungan deskripsi semua reward yang dipakai, misal "Diskon 10% • Per Transaksi".
  String get rewardSummary =>
      appliedRewards.map((r) => r.description).join(' + ');

  String get formattedDiscount => CurrencyFormatter.format(discountGiven);

  bool get hasFreeItems => freeItems.isNotEmpty;
}

// ── TransactionDetail — response GET /transactions/:id ───────────────────────

class TransactionDetail {
  final String id;
  final String invoiceNumber;
  final String status;

  // Parsed from API but intentionally not displayed in admin UI.
  // Admin only needs transaction status, not payment gateway status.
  final String paymentStatus;

  final double subtotal;
  final double totalDiscount;
  final double grandTotal;
  final double paidAmount;
  final double changeAmount;
  final String? paymentMethod;

  // Internal Midtrans fields — not shown in admin UI.
  // Keep parsing to avoid JSON decode errors if backend sends them.
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
    this.paymentMethod,
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
              (e) => TransactionPromotion.fromJson(e as Map<String, dynamic>),
            )
            .toList(),
      );

  // ── Computed ──────────────────────────────────────────────────────────────
  PaymentStyle get paymentStyle => PaymentStyle.of(paymentMethod);
  StatusStyle get statusStyle => StatusStyle.of(status);
  String get paymentMethodLabel => paymentStyle.label;
  bool get isCod => paymentMethod == 'cod' || paymentMethod == 'cash';
  bool get hasAddress => deliveryAddress != null;

  /// Apakah transaksi sudah di terminal state (tidak bisa diubah lagi).
  bool get isTerminal =>
      status == 'completed' || status == 'cancelled' || status == 'failed';

  /// Bagian alamat baris kedua: subregion, region, city
  String get addressLine2 => [
    deliverySubregion,
    deliveryRegion,
    deliveryCity,
  ].whereType<String>().join(', ');

  /// Set product_variant_id yang merupakan item gratis dari promo apapun
  /// di transaksi ini. Dipakai buat nandain item di "Item Pembelian" yang
  /// sebenarnya adalah hasil reward free_item, bukan pembelian biasa.
  Set<String> get freeItemVariantIds => promotions
      .expand((p) => p.freeItems)
      .map((f) => f.productVariantId)
      .toSet();

  // ── Formatters ────────────────────────────────────────────────────────────
  String get formattedGrandTotal => CurrencyFormatter.format(grandTotal);
  String get formattedSubtotal => CurrencyFormatter.format(subtotal);
  String get formattedPaidAmount => CurrencyFormatter.format(paidAmount);
  String get formattedChangeAmount => CurrencyFormatter.format(changeAmount);
  String get formattedTotalDiscount => CurrencyFormatter.format(totalDiscount);
}