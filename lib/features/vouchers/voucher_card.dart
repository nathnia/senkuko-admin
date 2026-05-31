import 'package:flutter/material.dart';
import 'package:senkukoadmin/constant/app_colors.dart';
import 'package:senkukoadmin/features/vouchers/voucher_model.dart';

class VoucherCard extends StatelessWidget {
  final VoucherData voucher;
  final VoidCallback onTap;
  final VoidCallback? onToggleStatus;
  final VoidCallback? onDelete;

  /// When false the action footer (toggle + delete) is hidden.
  /// Use in read-only preview contexts such as PromotionDetailPage.
  final bool showActions;

  const VoucherCard({
    super.key,
    required this.voucher,
    required this.onTap,
    this.onToggleStatus,
    this.onDelete,
    this.showActions = true,
  });

  Color get _statusColor {
    if (!voucher.isActive) return Colors.grey;
    if (voucher.isUsed) return Colors.orange;
    return const Color(0xFF2DC98E);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Column(
          children: [
            // ── Body ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  // Icon
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.confirmation_number_outlined,
                      size: 20,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          voucher.code,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'monospace',
                            letterSpacing: 0.5,
                            color: Color(0xFF1A1A2E),
                          ),
                        ),
                        const SizedBox(height: 3),
                        if (voucher.promotionName != null)
                          Text(
                            voucher.promotionName!,
                            style: const TextStyle(
                                fontSize: 11, color: Colors.grey),
                          ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            const Icon(Icons.repeat_rounded,
                                size: 11, color: Colors.grey),
                            const SizedBox(width: 3),
                            Text(
                              voucher.usageLimit == 0
                                  ? 'Unlimited'
                                  : '${voucher.usageCount}/${voucher.usageLimit}x dipakai',
                              style: const TextStyle(
                                  fontSize: 11, color: Colors.grey),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Status
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _statusColor.withAlpha(20),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          voucher.statusLabel,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Footer ────────────────────────────────────────────────────
            if (showActions)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(14)),
                  border:
                      Border(top: BorderSide(color: Colors.grey.shade100)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: onToggleStatus,
                      child: Icon(
                        voucher.isActive
                            ? Icons.toggle_on_rounded
                            : Icons.toggle_off_rounded,
                        size: 28,
                        color: voucher.isActive
                            ? AppColors.primary
                            : Colors.grey.shade400,
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: onDelete,
                      child: Icon(Icons.delete_outline_rounded,
                          size: 18, color: Colors.red.shade400),
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