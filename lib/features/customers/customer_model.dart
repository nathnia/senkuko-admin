import 'dart:convert';

CustomerModel customerModelFromJson(String str) =>
    CustomerModel.fromJson(json.decode(str));

String customerModelToJson(CustomerModel data) => json.encode(data.toJson());

// ── Enums ──────────────────────────────────────────────────────────────────

enum MemberType {
  regular,
  member,
  vip;

  static MemberType fromString(String value) {
    return MemberType.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => MemberType.regular,
    );
  }
}

enum CustomerStatus {
  active,
  inactive;

  static CustomerStatus fromString(String? value) {
    return CustomerStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == (value?.toLowerCase() ?? ''),
      orElse: () => CustomerStatus.active,
    );
  }
}

enum CustomerGroup {
  general,
  grosir;

  // Case-insensitive: handles "General", "GROSIR", "grosir", "general"
  static CustomerGroup fromString(String? value) {
    return CustomerGroup.values.firstWhere(
      (e) => e.name.toLowerCase() == (value?.toLowerCase() ?? ''),
      orElse: () => CustomerGroup.general,
    );
  }

  String get label {
    switch (this) {
      case CustomerGroup.general:
        return 'Eceran';
      case CustomerGroup.grosir:
        return 'Grosir';
    }
  }

  // Value yang dikirim ke API — sesuaikan dengan actual API
  String get apiValue {
    switch (this) {
      case CustomerGroup.general:
        return 'General';
      case CustomerGroup.grosir:
        return 'GROSIR';
    }
  }
}

// ── Model ──────────────────────────────────────────────────────────────────

class CustomerModel {
  bool success;
  List<CustomerData> data;

  CustomerModel({required this.success, required this.data});

  factory CustomerModel.fromJson(Map<String, dynamic> json) => CustomerModel(
    success: json["success"],
    data: List<CustomerData>.from(
      json["data"].map((x) => CustomerData.fromJson(x)),
    ),
  );

  Map<String, dynamic> toJson() => {
    "success": success,
    "data": List<dynamic>.from(data.map((x) => x.toJson())),
  };
}

class CustomerData {
  String id;
  String code;
  String name;
  String? phone;
  String? email;
  String? address;
  String? city;
  String? region;
  String? subregion;
  MemberType memberType;
  double totalSpend;
  CustomerStatus status;
  CustomerGroup customerGroup;
  DateTime createdAt;

  CustomerData({
    required this.id,
    required this.code,
    required this.name,
    this.phone,
    this.email,
    this.address,
    this.city,
    this.region,
    this.subregion,
    required this.memberType,
    required this.totalSpend,
    required this.status,
    required this.customerGroup,
    required this.createdAt,
  });

  bool get isActive => status == CustomerStatus.active;

  factory CustomerData.fromJson(Map<String, dynamic> json) => CustomerData(
    id: json["id"],
    code: json["code"] ?? '',
    name: json["name"],
    phone: json["phone"],
    email: json["email"],
    address: json["address"],
    city: json["city"],
    region: json["region"],
    subregion: json["subregion"],
    memberType: MemberType.fromString(
      json["member_type"] as String? ?? 'regular',
    ),
    totalSpend: double.tryParse(json["total_spend"].toString()) ?? 0.0,
    status: CustomerStatus.fromString(json["status"]),
    customerGroup: CustomerGroup.fromString(json["customer_group"]),
    createdAt: DateTime.parse(json["created_at"]),
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "code": code,
    "name": name,
    "phone": phone,
    "email": email,
    "address": address,
    "city": city,
    "region": region,
    "subregion": subregion,
    "member_type": memberType.name,
    "total_spend": totalSpend,
    "status": status.name,
    "customer_group": customerGroup.name,
    "created_at": createdAt.toIso8601String(),
  };
}