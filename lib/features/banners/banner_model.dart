import 'dart:convert';

// Backend kadang balikin is_active sebagai bool (true/false), kadang
// sebagai tinyint (1/0), kadang sebagai string ("1"/"0"/"true"/"false").
// Handle semuanya biar gak crash pas parsing.
bool _parseBool(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final v = value.trim().toLowerCase();
    return v == 'true' || v == '1';
  }
  return false;
}

BannerModel bannerModelFromJson(String str) =>
    BannerModel.fromJson(json.decode(str));

String bannerModelToJson(BannerModel data) => json.encode(data.toJson());

// ── Model ──────────────────────────────────────────────────────────────────

class BannerModel {
  bool success;
  List<BannerData> data;

  BannerModel({required this.success, required this.data});

  factory BannerModel.fromJson(Map<String, dynamic> json) => BannerModel(
    success: json["success"],
    data: List<BannerData>.from(
      json["data"].map((x) => BannerData.fromJson(x)),
    ),
  );

  Map<String, dynamic> toJson() => {
    "success": success,
    "data": List<dynamic>.from(data.map((x) => x.toJson())),
  };
}

class BannerData {
  String id;
  String imageUrl;
  String? title;
  int sortOrder;
  bool isActive;
  DateTime createdAt;
  DateTime updatedAt;

  BannerData({
    required this.id,
    required this.imageUrl,
    this.title,
    required this.sortOrder,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BannerData.fromJson(Map<String, dynamic> json) => BannerData(
    id: json["id"],
    imageUrl: json["image_url"] ?? '',
    title: json["title"],
    sortOrder: (json["sort_order"] is int)
        ? json["sort_order"]
        : int.tryParse(json["sort_order"].toString()) ?? 0,
    isActive: _parseBool(json["is_active"]),
    createdAt: DateTime.parse(json["created_at"]),
    updatedAt: DateTime.parse(json["updated_at"]),
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "image_url": imageUrl,
    "title": title,
    "sort_order": sortOrder,
    "is_active": isActive,
    "created_at": createdAt.toIso8601String(),
    "updated_at": updatedAt.toIso8601String(),
  };
}