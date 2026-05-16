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
      (e) => e.name == value,
      orElse: () => MemberType.regular,
    );
  }
}

enum CustomerStatus {
  active,
  inactive;

  static CustomerStatus fromString(String? value) {
    return CustomerStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => CustomerStatus.active,
    );
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
            json["data"].map((x) => CustomerData.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "success": success,
        "data": List<dynamic>.from(data.map((x) => x.toJson())),
      };
}

class CustomerData {
  String id;
  String name;
  String? phone;
  String? email;
  MemberType memberType;  // ← enum, bukan String
  double totalSpend;      // ← double, bukan String
  CustomerStatus status;  // ← enum, bukan String
  DateTime createdAt;

  CustomerData({
    required this.id,
    required this.name,
    this.phone,
    this.email,
    required this.memberType,
    required this.totalSpend,
    required this.status,
    required this.createdAt,
  });

  bool get isActive => status == CustomerStatus.active;

  factory CustomerData.fromJson(Map<String, dynamic> json) => CustomerData(
        id: json["id"],
        name: json["name"],
        phone: json["phone"],
        email: json["email"],
        memberType: MemberType.fromString(json["member_type"]),
        // API kadang return String, kadang num — handle keduanya
        totalSpend: double.parse(json["total_spend"].toString()),
        status: CustomerStatus.fromString(json["status"]),
        createdAt: DateTime.parse(json["created_at"]),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "phone": phone,
        "email": email,
        "member_type": memberType.name,
        "total_spend": totalSpend,
        "status": status.name,
        "created_at": createdAt.toIso8601String(),
      };
}