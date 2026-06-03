import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:senkukoadmin/constant/app_colors.dart';
import 'package:senkukoadmin/features/products/controllers/category_controller.dart';
import 'package:senkukoadmin/features/products/controllers/product_controller.dart';
import 'package:senkukoadmin/features/promotions/promotion_model.dart';

class PromotionConditionTile extends StatelessWidget {
  final PromotionCondition condition;
  final bool isLast;
  final VoidCallback onDelete;

  const PromotionConditionTile({
    super.key,
    required this.condition,
    required this.isLast,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(bottom: BorderSide(color: Color(0xFFF0F0F0))),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.secondary.withAlpha(18),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _icon(condition.conditionType),
              size: 16,
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _ConditionText(condition: condition),
          ),
          GestureDetector(
            onTap: onDelete,
            child: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Icon(
                Icons.close_rounded,
                size: 16,
                color: Colors.grey.shade400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _icon(String type) {
    switch (type) {
      case 'min_transaction_amount': return Icons.shopping_cart_outlined;
      case 'min_qty': return Icons.inventory_2_outlined;
      case 'specific_product': return Icons.storefront_outlined;
      case 'specific_category': return Icons.category_outlined;
      case 'member_type': return Icons.person_outline_rounded;
      default: return Icons.rule_rounded;
    }
  }
}

// ── Reactive text — observes productList & categoryList directly ──────────────

class _ConditionText extends StatelessWidget {
  final PromotionCondition condition;
  const _ConditionText({required this.condition});

  @override
  Widget build(BuildContext context) {
    final idr = NumberFormat.currency(
        locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    // Only specific_product and specific_category need reactive resolution.
    // For other types, skip Obx entirely.
    if (condition.conditionType == 'specific_product') {
      final productC = Get.find<ProductController>();
      return Obx(() {
        final product = productC.productList
            .firstWhereOrNull((p) => p.id == condition.targetId);
        final name = product?.name ?? _shortId(condition.targetId);
        return _textColumn(
          title: 'Produk: $name',
          subtitle: 'Harus membeli produk ini untuk mendapat promo',
        );
      });
    }

    if (condition.conditionType == 'specific_category') {
      final categoryC = Get.find<CategoryController>();
      return Obx(() {
        final cat = categoryC.categoryList
            .firstWhereOrNull((c) => c.id == condition.targetId);
        final name = cat == null
            ? _shortId(condition.targetId)
            : cat.parentName != null
                ? '${cat.parentName} › ${cat.name}'
                : cat.name;
        return _textColumn(
          title: 'Kategori: $name',
          subtitle: 'Harus membeli dari kategori ini untuk mendapat promo',
        );
      });
    }

    // Static types — no Obx needed
    final (title, subtitle) = _staticDescribe(condition, idr);
    return _textColumn(title: title, subtitle: subtitle);
  }

  (String, String) _staticDescribe(PromotionCondition c, NumberFormat idr) {
    switch (c.conditionType) {
      case 'min_transaction_amount':
        final amount = double.tryParse(c.value) ?? 0;
        return (
          'Min. belanja ${idr.format(amount)}',
          'Berlaku jika total transaksi ${_opLabel(c.operator)} ${idr.format(amount)}',
        );
      case 'min_qty':
        return (
          'Min. ${c.value} item',
          'Berlaku jika total item ${_opLabel(c.operator)} ${c.value}',
        );
      case 'member_type':
        final types = c.value.split(',').map((s) => s.trim()).join(', ');
        return (
          'Khusus member: $types',
          'Hanya berlaku untuk tipe member yang ditentukan',
        );
      default:
        return (c.conditionTypeLabel, '${_opLabel(c.operator)} ${c.value}');
    }
  }

  String _opLabel(String op) {
    switch (op) {
      case 'gte': return 'minimal';
      case 'lte': return 'maksimal';
      case 'eq': return 'sama dengan';
      case 'in': return 'salah satu dari';
      default: return op;
    }
  }

  String? _shortId(String? id) {
    if (id == null || id.isEmpty) return 'Tidak diketahui';
    return id.length > 8 ? '${id.substring(0, 8)}...' : id;
  }

  Widget _textColumn({required String title, required String subtitle}) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 11, color: Color(0xFFAAAAAA)),
          ),
        ],
      );
}