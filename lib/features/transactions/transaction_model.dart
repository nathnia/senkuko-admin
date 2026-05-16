import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:senkukoadmin/constant/currency_formatter.dart';

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
// Satuin color + bg + icon dalam satu class
// Kalau nanti ada metode baru, cukup tambah di sini saja

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
        return const PaymentStyle(
          color: Color(0xFF2DC98E),
          background: Color(0xFFE8FAF3),
          icon: Icons.payments_outlined,
          label: 'Tunai',
        );
      case 'transfer':
        return const PaymentStyle(
          color: Color(0xFF4F7EFF),
          background: Color(0xFFEEF3FF),
          icon: Icons.account_balance_outlined,
          label: 'Transfer',
        );
      case 'qris':
        return const PaymentStyle(
          color: Color(0xFF9B6DFF),
          background: Color(0xFFF3EEFF),
          icon: Icons.qr_code_outlined,
          label: 'QRIS',
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

// ── Model ─────────────────────────────────────────────────────────────────────

class TransactionData {
  final String id;
  final String invoiceNumber;
  final String status;
  final double subtotal;       // ← double, bukan String
  final double totalDiscount;  // ← double, bukan String
  final double grandTotal;     // ← double, bukan String
  final double paidAmount;     // ← double, bukan String
  final double changeAmount;   // ← double, bukan String
  final String paymentMethod;
  final DateTime transactedAt;
  final DateTime createdAt;
  final String? customerName;

  TransactionData({
    required this.id,
    required this.invoiceNumber,
    required this.status,
    required this.subtotal,
    required this.totalDiscount,
    required this.grandTotal,
    required this.paidAmount,
    required this.changeAmount,
    required this.paymentMethod,
    required this.transactedAt,
    required this.createdAt,
    this.customerName,
  });

  factory TransactionData.fromJson(Map<String, dynamic> json) =>
      TransactionData(
        id: json['id'],
        invoiceNumber: json['invoice_number'],
        status: json['status'],
        // API return String ("5000.00") — parse ke double
        subtotal: double.parse(json['subtotal'].toString()),
        totalDiscount: double.parse(json['total_discount'].toString()),
        grandTotal: double.parse(json['grand_total'].toString()),
        paidAmount: double.parse(json['paid_amount'].toString()),
        changeAmount: double.parse(json['change_amount'].toString()),
        paymentMethod: json['payment_method'],
        transactedAt: DateTime.parse(json['transacted_at']),
        createdAt: DateTime.parse(json['created_at']),
        customerName: json['customer_name'],
      );

  // ── Payment helpers ──────────────────────────────────────────────────────────
  PaymentStyle get paymentStyle => PaymentStyle.of(paymentMethod);
  String get paymentMethodLabel => paymentStyle.label;

  // ── Formatted getters ────────────────────────────────────────────────────────
  String get formattedGrandTotal => CurrencyFormatter.format(grandTotal);
  String get formattedSubtotal => CurrencyFormatter.format(subtotal);
  String get formattedPaidAmount => CurrencyFormatter.format(paidAmount);
  String get formattedChangeAmount => CurrencyFormatter.format(changeAmount);
  String get formattedTotalDiscount => CurrencyFormatter.format(totalDiscount);
}