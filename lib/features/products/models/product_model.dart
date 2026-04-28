import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:senkukoadmin/features/products/models/product_image_model.dart';

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

// lib/features/products/models/product_model.dart

class ProductData {
  final String id;
  final String name;
  final String skuCode;
  final String? description;
  final String? barcode;
  final int isActive;
  final DateTime createdAt;
  final String categoryName;        // ← tetap seperti asal
  final String? categoryId;         // ← tetap seperti asal

  // Field gambar (nullable)
  final List<ProductImageData>? images;

  ProductData({
    required this.id,
    required this.name,
    required this.skuCode,
    this.description,
    this.barcode,
    required this.isActive,
    required this.createdAt,
    required this.categoryName,      // ← tidak diubah
    this.categoryId,                 // ← tidak diubah
    this.images,
  });

factory ProductData.fromJson(Map<String, dynamic> json) {
  final rawImages = json['images'] ?? [];

  debugPrint("Parsing ${rawImages.length} images for product ${json['id']}");

  return ProductData(
    id: json['id']?.toString() ?? '',
    name: json['name']?.toString() ?? '',
    skuCode: json['sku_code']?.toString() ?? '',
    description: json['description'],
    barcode: json['barcode'],
    isActive: json['is_active'] ?? 0,
    createdAt: json['created_at'] != null 
        ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
        : DateTime.now(),
    categoryName: json['category_name']?.toString() ?? '',
    categoryId: json['category_id'],
    images: rawImages.isNotEmpty
        ? (rawImages as List)
            .map((e) => ProductImageData.fromJson(e as Map<String, dynamic>))
            .toList()
        : null,
  );
}
  // Helper getter untuk mendapatkan list URL gambar (string)
  List<String> get imageUrls => 
      images?.map((img) => img.imageUrl)
             .where((url) => url.isNotEmpty)
             .toList() ?? [];

}