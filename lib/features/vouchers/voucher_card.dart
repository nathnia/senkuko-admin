import 'package:flutter/material.dart';
import 'package:senkukoadmin/constant/app_colors.dart';
import 'package:senkukoadmin/features/vouchers/voucher_model.dart';

class VoucherCard extends StatelessWidget {
  final VoucherData voucher;
  final VoidCallback onTap;

  const VoucherCard({
    super.key,
    required this.voucher,
    required this.onTap,
  });

  Color get _statusColor {
    if (!voucher.isActive) return AppColors.subtext;
    if (voucher.isUsed) return AppColors.warning;
    return AppColors.primary;
  }

  Color get _statusBg {
    if (!voucher.isActive) return AppColors.background;
    if (voucher.isUsed) return AppColors.warningBg;
    return AppColors.successBg;
  }

  String get _statusLabel => voucher.statusLabel;

  String get _usageText {
    if (voucher.usageLimit == 0) return 'Tidak terbatas';
    return '${voucher.usageCount} dari ${voucher.usageLimit}x dipakai';
  }

  double? get _usageRatio {
    if (voucher.usageLimit == 0) return null;
    return (voucher.usageCount / voucher.usageLimit).clamp(0.0, 1.0);
  }

  Color get _usageColor {
    final r = _usageRatio;
    if (r == null) return AppColors.subtext;
    if (r >= 1.0) return AppColors.danger;
    if (r >= 0.7) return AppColors.warning;
    return AppColors.subtext;
  }

  Color get _barColor {
    final r = _usageRatio ?? 0;
    if (r >= 1.0) return AppColors.danger;
    if (r >= 0.7) return AppColors.warning;
    return AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
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
            // ── Icon ──────────────────────────────────────────────────────
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: _statusBg,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(
                Icons.confirmation_number_outlined,
                size: 18,
                color: _statusColor,
              ),
            ),
            const SizedBox(width: 12),

            // ── Info ──────────────────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    voucher.code,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'monospace',
                      letterSpacing: 0.4,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  if (voucher.promotionName != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      voucher.promotionName!,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.subtitle,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Icon(Icons.repeat_rounded,
                          size: 10, color: _usageColor),
                      const SizedBox(width: 3),
                      Text(
                        _usageText,
                        style: TextStyle(
                          fontSize: 11,
                          color: _usageColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  if (_usageRatio != null) ...[
                    const SizedBox(height: 5),
                    // FractionallySizedBox — no LayoutBuilder, no IntrinsicHeight
                    SizedBox(
                      height: 3,
                      child: Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          FractionallySizedBox(
                            widthFactor: _usageRatio,
                            child: Container(
                              decoration: BoxDecoration(
                                color: _barColor,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),

            // ── Status Badge ──────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _statusBg,
                borderRadius: BorderRadius.circular(20),
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
          ],
        ),
      ),
    );
  }
}