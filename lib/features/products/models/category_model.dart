// To parse this JSON data, do
//
//     final categoryModel = categoryModelFromJson(jsonString);

import 'dart:convert';

CategoryModel categoryModelFromJson(String str) => CategoryModel.fromJson(json.decode(str));

String categoryModelToJson(CategoryModel data) => json.encode(data.toJson());

class CategoryModel {
    bool success;
    List<CategoryData> data;

    CategoryModel({
        required this.success,
        required this.data,
    });

    factory CategoryModel.fromJson(Map<String, dynamic> json) => CategoryModel(
        success: json["success"],
        data: List<CategoryData>.from(json["data"].map((x) => CategoryData.fromJson(x))),
    );

    Map<String, dynamic> toJson() => {
        "success": success,
        "data": List<dynamic>.from(data.map((x) => x.toJson())),
    };
}

class CategoryData {
    String id;
    String name;
    String slug;
    int sortOrder;
    int isActive;
    DateTime createdAt;
    String? parentName;
    String? parentId;

    CategoryData({
        required this.id,
        required this.name,
        required this.slug,
        required this.sortOrder,
        required this.isActive,
        required this.createdAt,
        required this.parentName,
        required this.parentId,
    });

    factory CategoryData.fromJson(Map<String, dynamic> json) => CategoryData(
        id: json["id"],
        name: json["name"],
        slug: json["slug"],
        sortOrder: json["sort_order"],
        isActive: json["is_active"],
        createdAt: DateTime.parse(json["created_at"]),
        parentName: json["parent_name"],
        parentId: json["parent_id"],
    );

    Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "slug": slug,
        "sort_order": sortOrder,
        "is_active": isActive,
        "created_at": createdAt.toIso8601String(),
        "parent_name": parentName,
        "parent_id": parentId,
    };
}
