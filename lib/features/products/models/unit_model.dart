// To parse this JSON data, do
//
//     final unitModel = unitModelFromJson(jsonString);

import 'dart:convert';

UnitModel unitModelFromJson(String str) => UnitModel.fromJson(json.decode(str));

String unitModelToJson(UnitModel data) => json.encode(data.toJson());

class UnitModel {
    bool success;
    List<UnitData> data;

    UnitModel({
        required this.success,
        required this.data,
    });

    factory UnitModel.fromJson(Map<String, dynamic> json) => UnitModel(
        success: json["success"],
        data: List<UnitData>.from(json["data"].map((x) => UnitData.fromJson(x))),
    );

    Map<String, dynamic> toJson() => {
        "success": success,
        "data": List<dynamic>.from(data.map((x) => x.toJson())),
    };
}

class UnitData {
    String id;
    String name;
    String symbol;
    String description;

    UnitData({
        required this.id,
        required this.name,
        required this.symbol,
        required this.description,
    });

    factory UnitData.fromJson(Map<String, dynamic> json) => UnitData(
        id: json["id"],
        name: json["name"],
        symbol: json["symbol"],
        description: json["description"],
    );

    Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "symbol": symbol,
        "description": description,
    };
}
