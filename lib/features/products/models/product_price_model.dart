import 'dart:convert';

ProductPriceModel productPriceModelFromJson(String str) =>
    ProductPriceModel.fromJson(json.decode(str));

String productPriceModelToJson(ProductPriceModel data) =>
    json.encode(data.toJson());

class ProductPriceModel {
  bool success;
  List<PriceData> data;

  ProductPriceModel({
    required this.success,
    required this.data,
  });

  factory ProductPriceModel.fromJson(Map<String, dynamic> json) =>
      ProductPriceModel(
        success: json["success"] == true,
        data: (json["data"] as List? ?? [])
            .map((x) => PriceData.fromJson(x))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        "success": success,
        "data": data.map((x) => x.toJson()).toList(),
      };
}

class PriceData {
  String id;
  int minQty;
  String price;

  dynamic validFrom;
  dynamic validTo;

  bool isActive; 

  String productVariantId;
  String productVariantName;
  String priceListId;
  String priceListName;
  String priceListCode;

  PriceData({
    required this.id,
    required this.minQty,
    required this.price,
    required this.validFrom,
    required this.validTo,
    required this.isActive,
    required this.productVariantId,
    required this.productVariantName,
    required this.priceListId,
    required this.priceListName,
    required this.priceListCode,
  });

  factory PriceData.fromJson(Map<String, dynamic> json) => PriceData(
        id: json["id"] ?? "",
        minQty: json["min_qty"] ?? 0,
        price: json["price"]?.toString() ?? "0",
        validFrom: json["valid_from"],
        validTo: json["valid_to"],
        isActive: json["is_active"] == true || json["is_active"] == 1,
        productVariantId: json["product_variant_id"] ?? "",
        productVariantName: json["product_variant_name"] ?? "",
        priceListId: json["price_list_id"] ?? "",
        priceListName: json["price_list_name"] ?? "",
        priceListCode: json["price_list_code"] ?? "",
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "min_qty": minQty,
        "price": price,
        "valid_from": validFrom,
        "valid_to": validTo,
        "is_active": isActive ? 1 : 0,
        "product_variant_id": productVariantId,
        "product_variant_name": productVariantName,
        "price_list_id": priceListId,
        "price_list_name": priceListName,
        "price_list_code": priceListCode,
      };
}