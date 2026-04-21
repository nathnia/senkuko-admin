import 'dart:convert';

ProductModel productModelFromJson(String str) =>
    ProductModel.fromJson(json.decode(str));

class ProductModel {
  bool success;
  List<ProductData> data;

  ProductModel({required this.success, required this.data});

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      success: json["success"],
      data: List<ProductData>.from(
        json["data"].map((x) => ProductData.fromJson(x)),
      ),
    );
  }
}
class ProductData {
  String id;
  String name;
  String skuCode;
  String? description;        // ← ubah jadi nullable
  String? barcode;            // ← ubah jadi nullable
  int isActive;
  DateTime createdAt;
  String categoryName;
  String? categoryId;         // ← TAMBAHKAN INI

  ProductData({
    required this.id,
    required this.name,
    required this.skuCode,
    this.description,
    this.barcode,
    required this.isActive,
    required this.createdAt,
    required this.categoryName,
    this.categoryId,
  });

  factory ProductData.fromJson(Map<String, dynamic> json) {
    return ProductData(
      id: json["id"] ?? "",
      name: json["name"] ?? "",
      skuCode: json["sku_code"] ?? "",
      description: json["description"],
      barcode: json["barcode"],
      isActive: json["is_active"] ?? 0,
      createdAt: DateTime.tryParse(json["created_at"] ?? "") ?? DateTime.now(),
      categoryName: json["category_name"] ?? "",
      categoryId: json["category_id"],        // ← tambahkan
    );
  }
}