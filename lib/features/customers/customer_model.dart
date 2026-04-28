// To parse this JSON data, do
//
//     final customerModel = customerModelFromJson(jsonString);

import 'dart:convert';

CustomerModel customerModelFromJson(String str) => CustomerModel.fromJson(json.decode(str));

String customerModelToJson(CustomerModel data) => json.encode(data.toJson());

class CustomerModel {
    bool success;
    List<CustomerData> data;

    CustomerModel({
        required this.success,
        required this.data,
    });

    factory CustomerModel.fromJson(Map<String, dynamic> json) => CustomerModel(
        success: json["success"],
        data: List<CustomerData>.from(json["data"].map((x) => CustomerData.fromJson(x))),
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
    String memberType;
    String totalSpend;
    DateTime createdAt;

    CustomerData({
        required this.id,
        required this.name,
        required this.phone,
        required this.email,
        required this.memberType,
        required this.totalSpend,
        required this.createdAt,
    });

    factory CustomerData.fromJson(Map<String, dynamic> json) => CustomerData(
        id: json["id"],
        name: json["name"],
        phone: json["phone"],
        email: json["email"],
        memberType: json["member_type"],
        totalSpend: json["total_spend"],
        createdAt: DateTime.parse(json["created_at"]),
    );

    Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "phone": phone,
        "email": email,
        "member_type": memberType,
        "total_spend": totalSpend,
        "created_at": createdAt.toIso8601String(),
    };
}
