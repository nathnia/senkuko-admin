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

  // voucher_model.dart — tambah di class VoucherData
  VoucherData copyWith({
    String? id,
    String? promotionId,
    String? code,
    String? status,
    int? usageLimit,
    int? usageCount,
    DateTime? createdAt,
    String? promotionName,
    String? promotionType,
  }) => VoucherData(
    id: id ?? this.id,
    promotionId: promotionId ?? this.promotionId,
    code: code ?? this.code,
    status: status ?? this.status,
    usageLimit: usageLimit ?? this.usageLimit,
    usageCount: usageCount ?? this.usageCount,
    createdAt: createdAt ?? this.createdAt,
    promotionName: promotionName ?? this.promotionName,
    promotionType: promotionType ?? this.promotionType,
  );

  factory VoucherData.fromJson(Map<String, dynamic> json) => VoucherData(
    id: json['id'],
    promotionId: json['promotion_id'],
    code: json['code'],
    status: json['status'],
    usageLimit: json['usage_limit'],
    usageCount: json['usage_count'],
    // FIX
    createdAt: json['created_at'] != null
        ? DateTime.parse(json['created_at']).toLocal()
        : DateTime.now(),
    promotionName: json['promotion_name'],
    promotionType: json['promotion_type'], // tetap, sudah nullable
  );

  bool get isActive => status == 'active';
  bool get isUsed => usageCount >= usageLimit && usageLimit != 0;

  String get statusLabel {
    if (status == 'inactive') return 'Tidak Aktif';
    if (isUsed) return 'Habis';
    return 'Aktif';
  }
}
