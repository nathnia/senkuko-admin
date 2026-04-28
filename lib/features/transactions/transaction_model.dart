import 'dart:convert';

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

class TransactionData {
  final String id;
  final String invoiceNumber;
  final String status;
  final String subtotal;
  final String totalDiscount;
  final String grandTotal;
  final String paidAmount;
  final String changeAmount;
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
        subtotal: json['subtotal'],
        totalDiscount: json['total_discount'],
        grandTotal: json['grand_total'],
        paidAmount: json['paid_amount'],
        changeAmount: json['change_amount'],
        paymentMethod: json['payment_method'],
        transactedAt: DateTime.parse(json['transacted_at']),
        createdAt: DateTime.parse(json['created_at']),
        customerName: json['customer_name'],
      );

  String get paymentMethodLabel {
    switch (paymentMethod) {
      case 'cash':
        return 'Tunai';
      case 'transfer':
        return 'Transfer';
      case 'qris':
        return 'QRIS';
      default:
        return paymentMethod;
    }
  }

  String get formattedGrandTotal => CurrencyFormatter.format(grandTotal);
  String get formattedSubtotal => CurrencyFormatter.format(subtotal);
  String get formattedPaidAmount => CurrencyFormatter.format(paidAmount);
  String get formattedChangeAmount => CurrencyFormatter.format(changeAmount);
}
