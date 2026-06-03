import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:senkukoadmin/constant/app_colors.dart';
import 'package:senkukoadmin/features/products/controllers/product_variant_controller.dart';
import 'package:senkukoadmin/features/promotions/promotion_model.dart';

class PromotionRewardTile extends StatelessWidget {
  final PromotionReward reward;
  final bool isLast;
  final VoidCallback onDelete;

  const PromotionRewardTile({
    super.key,
    required this.reward,
    required this.isLast,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final idr = NumberFormat.currency(
        locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

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
              color: AppColors.successBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _icon(reward.rewardType),
              size: 16,
              color: AppColors.success,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: reward.rewardType == 'free_item'
                ? _freeItemContent(idr)
                : _discountContent(idr),
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

  // ── Discount content ──────────────────────────────────────────────────────

  Widget _discountContent(NumberFormat idr) {
    final title = reward.rewardType == 'discount_percent'
        ? 'Diskon ${reward.discountValue?.toStringAsFixed(0) ?? '0'}%'
        : 'Potongan ${idr.format(reward.discountValue ?? 0)}';

    final maxDisc = (reward.maxDiscountAmount ?? 0) > 0
        ? 'Maks. ${idr.format(reward.maxDiscountAmount)}'
        : 'Tanpa batas maksimal';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(width: 6),
            _chip(reward.discountModeLabel),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          maxDisc,
          style: const TextStyle(fontSize: 11, color: Color(0xFFAAAAAA)),
        ),
      ],
    );
  }

  // ── Free item content — reactive ──────────────────────────────────────────

  Widget _freeItemContent(NumberFormat idr) {
    final qty = reward.freeQty ?? 1;

    return Obx(() {
      final variantName = _resolveVariantName(reward.freeVariantId);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '$qty item gratis',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              const SizedBox(width: 6),
              _chip('Gratis Item'),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              const Icon(
                Icons.storefront_outlined,
                size: 11,
                color: Color(0xFFAAAAAA),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  variantName,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFFAAAAAA),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      );
    });
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _resolveVariantName(String? variantId) {
    if (variantId == null || variantId.isEmpty) return 'Variant tidak diketahui';
    try {
      final variantC = Get.find<ProductVariantController>();
      final variant = variantC.allVariants
          .firstWhereOrNull((v) => v.id == variantId);
      return variant?.name ?? _shortId(variantId);
    } catch (_) {
      return _shortId(variantId);
    }
  }

  String _shortId(String id) =>
      '${id.substring(0, id.length.clamp(0, 8))}...';

  Widget _chip(String label) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.successBg,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppColors.success,
          ),
        ),
      );

  IconData _icon(String type) {
    switch (type) {
      case 'discount_percent':
        return Icons.percent_rounded;
      case 'discount_fixed':
        return Icons.money_off_rounded;
      case 'free_item':
        return Icons.card_giftcard_rounded;
      default:
        return Icons.redeem_rounded;
    }
  }
}