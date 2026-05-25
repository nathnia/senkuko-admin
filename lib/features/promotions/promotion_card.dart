import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:senkukoadmin/constant/app_colors.dart';
import 'package:senkukoadmin/features/promotions/promotion_model.dart';

class PromotionCard extends StatelessWidget {
  final PromotionData promotion;
  final VoidCallback onTap;
  final VoidCallback onToggleActive;
  final VoidCallback onDelete;

  const PromotionCard({
    super.key,
    required this.promotion,
    required this.onTap,
    required this.onToggleActive,
    required this.onDelete,
  });

  Color get _statusColor {
    if (!promotion.isActive) return Colors.grey;
    if (promotion.isExpired) return Colors.orange;
    return AppColors.primary;
  }

  String get _statusLabel {
    if (!promotion.isActive) return 'Tidak Aktif';
    if (promotion.isExpired) return 'Kedaluwarsa';
    return 'Aktif';
  }

  Color get _typeBadgeColor {
    switch (promotion.type) {
      case 'discount_percent':
        return Colors.purple;
      case 'discount_fixed':
        return Colors.teal;
      case 'free_item':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('dd MMM yyyy', 'id_ID');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
              child: Row(
                children: [
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
                            border: Border.all(
                                color: Colors.grey.shade300, width: 0.5),
                          ),
                          child: Text(
                            promotion.code,
                            style: const TextStyle(
                              fontSize: 10,
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: _typeBadgeColor.withAlpha(20),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      promotion.typeLabel,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: _typeBadgeColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Divider(height: 1, color: Colors.grey.shade100),

            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (promotion.description != null &&
                      promotion.description!.isNotEmpty) ...[
                    Text(
                      promotion.description!,
                      style: TextStyle(
                          fontSize: 11, color: AppColors.subtext),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5),
                  ],
                  Row(
                    children: [
                      Icon(Icons.calendar_today_outlined,
                          size: 10, color: Colors.grey.shade400),
                      const SizedBox(width: 4),
                      Text(
                        '${df.format(promotion.validFrom)} – ${df.format(promotion.validTo)}',
                        style: TextStyle(
                            fontSize: 11, color: AppColors.subtext),
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
                        style: TextStyle(
                            fontSize: 11, color: AppColors.subtext),
                      ),
                      if (promotion.stackable) ...[
                        const SizedBox(width: 8),
                        Icon(Icons.layers_outlined,
                            size: 10, color: Colors.grey.shade400),
                        const SizedBox(width: 3),
                        Text('Stackable',
                            style: TextStyle(
                                fontSize: 11, color: AppColors.subtext)),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(12)),
                border: Border(top: BorderSide(color: Colors.grey.shade100)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: _statusColor.withAlpha(20),
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
                  const Spacer(),
                  GestureDetector(
                    onTap: onToggleActive,
                    child: Icon(
                      promotion.isActive
                          ? Icons.toggle_on_rounded
                          : Icons.toggle_off_rounded,
                      size: 26,
                      color: promotion.isActive
                          ? AppColors.primary
                          : Colors.grey.shade400,
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: onDelete,
                    child: Icon(Icons.delete_outline_rounded,
                        size: 16, color: Colors.red.shade400),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}