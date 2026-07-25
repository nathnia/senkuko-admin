// To parse this JSON data, do
//
//     final productVariantModel = productVariantModelFromJson(jsonString);

import 'dart:convert';

ProductVariantModel productVariantModelFromJson(String str) =>
    ProductVariantModel.fromJson(json.decode(str));

String productVariantModelToJson(ProductVariantModel data) =>
    json.encode(data.toJson());

class ProductVariantModel {
  bool success;
  List<VariantData> data;

  ProductVariantModel({required this.success, required this.data});

  factory ProductVariantModel.fromJson(Map<String, dynamic> json) =>
      ProductVariantModel(
        success: json["success"] ?? false,
        data: List<VariantData>.from(
          (json["data"]?["variants"] ?? json["data"] ?? []).map(
            (x) => VariantData.fromJson(x),
          ),
        ),
      );

  Map<String, dynamic> toJson() => {
    "success": success,
    "data": List<dynamic>.from(data.map((x) => x.toJson())),
  };
}

class VariantData {
  String id;
  String name;
  String? barcode;
  int stockQty;
  int minStockQty;
  int crisisStock;
  String conversionFactor;
  int isBaseUnit;
  int isActive;
  DateTime createdAt;
  String productId;
  String productName;
  String? unitId;
  String? unitName;
  String? unitSymbol;

  VariantData({
    required this.id,
    required this.name,
    this.barcode,
    required this.stockQty,
    required this.minStockQty,
    required this.crisisStock,
    required this.conversionFactor,
    required this.isBaseUnit,
    required this.isActive,
    required this.createdAt,
    required this.productId,
    required this.productName,
    this.unitId,
    this.unitName,
    this.unitSymbol,
  });

  factory VariantData.fromJson(Map<String, dynamic> json) {
    return VariantData(
      id: json["id"] ?? "",
      name: json["name"] ?? "",
      barcode: json["barcode"],
      stockQty: json["stock_qty"] ?? 0,
      minStockQty: json["min_stock_qty"] ?? 0,
      crisisStock: json["crisis_stock"] ?? 0,
      conversionFactor: json["conversion_factor"]?.toString() ?? "1.0",
      isBaseUnit: json["is_base_unit"] ?? 0,
      isActive: json["is_active"] ?? 0,
      createdAt: DateTime.tryParse(json["created_at"] ?? "") ?? DateTime.now(),
      productId: json["product_id"] ?? "",
      productName: json["product_name"] ?? "",
      unitId: json["unit_id"]?.toString(), // Pastikan String
      unitName: json["unit_name"]?.toString(),
      unitSymbol: json["unit_symbol"]?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "barcode": barcode,
    "stock_qty": stockQty,
    "min_stock_qty": minStockQty,
    "crisis_stock": crisisStock,
    "conversion_factor": conversionFactor,
    "is_base_unit": isBaseUnit,
    "is_active": isActive,
    "created_at": createdAt.toIso8601String(),
    "product_id": productId,
    "product_name": productName,
    "unit_id": unitId,
    "unit_name": unitName,
    "unit_symbol": unitSymbol,
  };
}