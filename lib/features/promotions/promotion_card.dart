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

  // Card di-dim kalau promo gak lagi "usable" — dinonaktifkan admin
  // ATAU udah lewat valid_to. Sama pattern-nya kayak VoucherCard.
  bool get _isDimmed => !promotion.isActive || promotion.isExpired;

  Color get _statusColor {
    if (!promotion.isActive) return AppColors.subtext;
    if (promotion.isExpired) return AppColors.danger;
    return AppColors.success;
  }

  Color get _statusBg {
    if (!promotion.isActive) return AppColors.background;
    if (promotion.isExpired) return AppColors.dangerBg;
    return AppColors.successBg;
  }

  String get _statusLabel {
    if (!promotion.isActive) return 'Tidak Aktif';
    if (promotion.isExpired) return 'Kedaluwarsa';
    return 'Aktif';
  }

  // Type badge sekarang murni informatif (bukan status/alert), jadi
  // warnanya netral & konsisten terlepas dari tipe promonya apa.
  IconData get _typeIcon {
    switch (promotion.type) {
      case 'discount_percent':
        return Icons.percent_rounded;
      case 'discount_fixed':
        return Icons.money_off_rounded;
      case 'free_item':
        return Icons.card_giftcard_rounded;
      default:
        return Icons.local_offer_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('dd MMM yyyy', 'id_ID');

    return Opacity(
      opacity: _isDimmed ? 0.5 : 1.0,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ── Icon ──────────────────────────────────────────────────
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(18),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(
                  _typeIcon,
                  size: 18,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),

              // ── Info ──────────────────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      promotion.name,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A2E),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            promotion.code,
                            style: const TextStyle(
                              fontSize: 10,
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.4,
                              color: Color(0xFF1A1A2E),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          promotion.typeLabel,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppColors.subtitle,
                          ),
                        ),
                      ],
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
                              ? 'Tidak terbatas'
                              : '${promotion.usageCount} dari ${promotion.usageLimit}x dipakai',
                          style: const TextStyle(
                              fontSize: 11, color: Color(0xFFAAAAAA)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),

              // ── Status Badge (dot + pill, match VoucherCard) ──────────
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _statusBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: _statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _statusLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}