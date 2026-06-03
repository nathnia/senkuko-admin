import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:senkukoadmin/constant/app_colors.dart';
import 'package:senkukoadmin/features/promotions/promotion_model.dart';

class PromotionCard extends StatelessWidget {
  final PromotionData promotion;
  final VoidCallback onTap;

  const PromotionCard({
    super.key,
    required this.promotion,
    required this.onTap,
  });

  Color get _statusColor {
    if (!promotion.isActive) return AppColors.subtext;
    if (promotion.isExpired) return AppColors.warning;
    return AppColors.primary;
  }

  Color get _statusBgColor {
    if (!promotion.isActive) return AppColors.subtext.withAlpha(20);
    if (promotion.isExpired) return AppColors.warningBg;
    return AppColors.primary.withAlpha(20);
  }

  String get _statusLabel {
    if (!promotion.isActive) return 'Tidak Aktif';
    if (promotion.isExpired) return 'Kedaluwarsa';
    return 'Aktif';
  }

  Color get _typeFgColor {
    switch (promotion.type) {
      case 'discount_percent':
      case 'discount_fixed':
        return AppColors.success;
      case 'free_item':
        return AppColors.warning;
      default:
        return AppColors.subtext;
    }
  }

  Color get _typeBgColor {
    switch (promotion.type) {
      case 'discount_percent':
      case 'discount_fixed':
        return AppColors.successBg;
      case 'free_item':
        return AppColors.warningBg;
      default:
        return AppColors.subtext.withAlpha(20);
    }
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('dd MMM yyyy', 'id_ID');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // ── Icon ─────────────────────────────────────────────────────
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(18),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(
                Icons.local_offer_outlined,
                size: 18,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),

            // ── Info ─────────────────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    promotion.name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(4),
                      border:
                          Border.all(color: Colors.grey.shade300, width: 0.5),
                    ),
                    child: Text(
                      promotion.code,
                      style: const TextStyle(
                        fontSize: 10,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Icon(Icons.calendar_today_outlined,
                          size: 10, color: Colors.grey.shade400),
                      const SizedBox(width: 4),
                      Text(
                        '${df.format(promotion.validFrom)} – ${df.format(promotion.validTo)}',
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xFFAAAAAA)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(Icons.repeat_rounded,
                          size: 10, color: Colors.grey.shade400),
                      const SizedBox(width: 4),
                      Text(
                        promotion.usageLimit == 0
                            ? 'Unlimited'
                            : '${promotion.usageCount}/${promotion.usageLimit}x dipakai',
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xFFAAAAAA)),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Badges ───────────────────────────────────────────────────
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: _statusBgColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _statusLabel,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: _statusColor,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _typeBgColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    promotion.typeLabel,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: _typeFgColor,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}