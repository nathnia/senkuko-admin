import 'dart:convert';

PromotionListModel promotionListModelFromJson(String str) =>
    PromotionListModel.fromJson(json.decode(str));

class PromotionListModel {
  final bool success;
  final List<PromotionData> data;

  PromotionListModel({required this.success, required this.data});

  factory PromotionListModel.fromJson(Map<String, dynamic> json) =>
      PromotionListModel(
        success: json['success'],
        data: List<PromotionData>.from(
          json['data'].map((x) => PromotionData.fromJson(x)),
        ),
      );
}

class PromotionData {
  final String id;
  final String name;
  final String code;
  final String type;
  final String? description;
  final DateTime validFrom;
  final DateTime validTo;
  final int usageLimit;
  final int usageCount;
  final bool isActive;
  final bool stackable;
  final DateTime createdAt;
  final List<PromotionCondition> conditions;
  final List<PromotionReward> rewards;

  PromotionData({
    required this.id,
    required this.name,
    required this.code,
    required this.type,
    this.description,
    required this.validFrom,
    required this.validTo,
    required this.usageLimit,
    required this.usageCount,
    required this.isActive,
    required this.stackable,
    required this.createdAt,
    this.conditions = const [],
    this.rewards = const [],
  });

  factory PromotionData.fromJson(Map<String, dynamic> json) => PromotionData(
        id: json['id'],
        name: json['name'],
        code: json['code'],
        type: json['type'],
        description: json['description'],
        validFrom: DateTime.parse(json['valid_from']),
        validTo: DateTime.parse(json['valid_to']),
        usageLimit: json['usage_limit'],
        usageCount: json['usage_count'],
        isActive: json['is_active'] == 1 || json['is_active'] == true,
        stackable: json['stackable'] == 1 || json['stackable'] == true,
        createdAt: DateTime.parse(json['created_at']),
        conditions: (json['conditions'] as List<dynamic>?)
                ?.map((e) => PromotionCondition.fromJson(e))
                .toList() ??
            [],
        rewards: (json['rewards'] as List<dynamic>?)
                ?.map((e) => PromotionReward.fromJson(e))
                .toList() ??
            [],
      );

  bool get isExpired => DateTime.now().isAfter(validTo);
  bool get isValid => isActive && !isExpired;

  String get typeLabel {
    switch (type) {
      case 'discount_percent':
        return 'Diskon %';
      case 'discount_fixed':
        return 'Diskon Nominal';
      case 'free_item':
        return 'Gratis Item';
      default:
        return type;
    }
  }
}

class PromotionCondition {
  final String id;
  final String promotionId;
  final String conditionType;
  final String operator;
  final String value;
  final String? targetType;
  final String? targetId;

  PromotionCondition({
    required this.id,
    required this.promotionId,
    required this.conditionType,
    required this.operator,
    required this.value,
    this.targetType,
    this.targetId,
  });

  factory PromotionCondition.fromJson(Map<String, dynamic> json) =>
      PromotionCondition(
        id: json['id'],
        promotionId: json['promotion_id'],
        conditionType: json['condition_type'],
        operator: json['operator'],
        value: json['value'],
        targetType: json['target_type'],
        targetId: json['target_id'],
      );

  String get conditionTypeLabel {
    switch (conditionType) {
      case 'min_transaction_amount':
        return 'Min. Total Belanja';
      case 'min_qty':
        return 'Min. Qty Item';
      case 'specific_product':
        return 'Produk Tertentu';
      case 'specific_category':
        return 'Kategori Tertentu';
      case 'member_type':
        return 'Tipe Member';
      default:
        return conditionType;
    }
  }

  String get operatorLabel {
    switch (operator) {
      case 'gte':
        return '>=';
      case 'lte':
        return '<=';
      case 'eq':
        return '=';
      case 'in':
        return 'in';
      default:
        return operator;
    }
  }
}

class PromotionReward {
  final String id;
  final String promotionId;
  final String rewardType;
  final double? discountValue;
  final String? discountMode;
  final double? maxDiscountAmount;
  final String? freeVariantId;
  final int? freeQty;

  PromotionReward({
    required this.id,
    required this.promotionId,
    required this.rewardType,
    this.discountValue,
    this.discountMode,
    this.maxDiscountAmount,
    this.freeVariantId,
    this.freeQty,
  });

  factory PromotionReward.fromJson(Map<String, dynamic> json) => PromotionReward(
        id: json['id'],
        promotionId: json['promotion_id'],
        rewardType: json['reward_type'],
        discountValue: (json['discount_value'] as num?)?.toDouble(),
        discountMode: json['discount_mode'],
        maxDiscountAmount: (json['max_discount_amount'] as num?)?.toDouble(),
        freeVariantId: json['free_variant_id'],
        freeQty: json['free_qty'],
      );

  String get rewardTypeLabel {
    switch (rewardType) {
      case 'discount_percent':
        return 'Diskon %';
      case 'discount_fixed':
        return 'Diskon Nominal';
      case 'free_item':
        return 'Gratis Item';
      default:
        return rewardType;
    }
  }

  String get discountModeLabel {
    switch (discountMode) {
      case 'per_transaction':
        return 'Per Transaksi';
      case 'per_item':
        return 'Per Item';
      default:
        return discountMode ?? '';
    }
  }
}