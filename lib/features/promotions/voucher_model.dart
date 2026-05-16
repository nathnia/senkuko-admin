import 'dart:convert';

VoucherListModel voucherListModelFromJson(String str) =>
    VoucherListModel.fromJson(json.decode(str));

class VoucherListModel {
  final bool success;
  final List<VoucherData> data;

  VoucherListModel({required this.success, required this.data});

  factory VoucherListModel.fromJson(Map<String, dynamic> json) =>
      VoucherListModel(
        success: json['success'],
        data: List<VoucherData>.from(
          json['data'].map((x) => VoucherData.fromJson(x)),
        ),
      );
}

class VoucherData {
  final String id;
  final String promotionId;
  final String code;
  final String status;
  final int usageLimit;
  final int usageCount;
  final DateTime createdAt;

  // optional: promotion info kalau di-join dari backend
  final String? promotionName;
  final String? promotionType;

  VoucherData({
    required this.id,
    required this.promotionId,
    required this.code,
    required this.status,
    required this.usageLimit,
    required this.usageCount,
    required this.createdAt,
    this.promotionName,
    this.promotionType,
  });

  factory VoucherData.fromJson(Map<String, dynamic> json) => VoucherData(
        id: json['id'],
        promotionId: json['promotion_id'],
        code: json['code'],
        status: json['status'],
        usageLimit: json['usage_limit'],
        usageCount: json['usage_count'],
        createdAt: DateTime.parse(json['created_at']),
        promotionName: json['promotion_name'],
        promotionType: json['promotion_type'],
      );

  bool get isActive => status == 'active';
  bool get isUsed => usageCount >= usageLimit && usageLimit != 0;

  String get statusLabel {
    if (status == 'inactive') return 'Tidak Aktif';
    if (isUsed) return 'Habis';
    return 'Aktif';
  }
}