// To parse this JSON data, do
//
//     final priceListModel = priceListModelFromJson(jsonString);

import 'dart:convert';

PriceListModel priceListModelFromJson(String str) =>
    PriceListModel.fromJson(json.decode(str));

String priceListModelToJson(PriceListModel data) => json.encode(data.toJson());

class PriceListModel {
  bool success;
  List<PricelistData> data;

  PriceListModel({required this.success, required this.data});

  factory PriceListModel.fromJson(Map<String, dynamic> json) => PriceListModel(
    success: json["success"] ?? false,
    data: json["data"] == null
        ? []
        : List<PricelistData>.from(
            json["data"].map((x) => PricelistData.fromJson(x)),
          ),
  );

  Map<String, dynamic> toJson() => {
    "success": success,
    "data": List<dynamic>.from(data.map((x) => x.toJson())),
  };
}

class PricelistData {
  String id;
  String name;
  String code;
  String description;
  int isActive;

  PricelistData({
    required this.id,
    required this.name,
    required this.code,
    required this.description,
    required this.isActive,
  });

  factory PricelistData.fromJson(Map<String, dynamic> json) => PricelistData(
    id: json["id"] ?? "",
    name: json["name"] ?? "",
    code: json["code"] ?? "",
    description: json["description"] ?? "",
    isActive: json["is_active"] ?? 0,
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "code": code,
    "description": description,
    "is_active": isActive,
  };
}
