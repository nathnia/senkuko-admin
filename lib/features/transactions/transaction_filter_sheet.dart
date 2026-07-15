import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:senkukoadmin/constant/app_colors.dart';
import 'package:senkukoadmin/constant/currency_formatter.dart';
import 'package:senkukoadmin/features/transactions/transaction_controller.dart';

void showTransactionFilterSheet(
  BuildContext context,
  TransactionController controller,
) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.background,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(ctx).viewInsets.bottom +
            MediaQuery.of(ctx).padding.bottom +
            20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ── Reset (kanan) ────────────────────────────────────────────
          Obx(() {
            if (!controller.hasActiveDateFilter) {
              return const SizedBox.shrink();
            }
            return Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: () {
                  controller.resetDateFilter();
                  Get.back();
                },
                child: Text(
                  'Reset',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.danger,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 12),

          // ── Sort order ───────────────────────────────────────────────
          Text(
            'URUTKAN',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 11,
              letterSpacing: 0.5,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 10),
          Obx(
            () => Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _FilterPillChip(
                  label: 'Terbaru',
                  icon: Icons.arrow_downward_rounded,
                  isSelected: controller.sortOrder.value == 'terbaru',
                  onTap: () => controller.updateSortOrder('terbaru'),
                ),
                _FilterPillChip(
                  label: 'Terlama',
                  icon: Icons.arrow_upward_rounded,
                  isSelected: controller.sortOrder.value == 'terlama',
                  onTap: () => controller.updateSortOrder('terlama'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // ── Date chips ───────────────────────────────────────────────
          Text(
            'TANGGAL',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 11,
              letterSpacing: 0.5,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 10),
          Obx(() {
            final current = controller.selectedQuickDate.value;
            final range = controller.selectedDateRange.value;
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: controller.quickDateFilters.map((f) {
                final isSelected = current == f;
                final displayLabel =
                    (f == 'Custom' && isSelected && range != null)
                    ? '${DateFormatter.formatShort(range.start)} – ${DateFormatter.formatShort(range.end)}'
                    : f;
                return _FilterPillChip(
                  label: displayLabel,
                  icon: f == 'Custom' ? Icons.date_range_outlined : null,
                  isSelected: isSelected,
                  onTap: () async {
                    if (f == 'Custom') {
                      await controller.pickDateRange(ctx);
                    } else {
                      controller.updateQuickDate(f);
                    }
                    // Tutup sheet setelah pilih, kecuali Custom yang buka
                    // date picker dulu
                    if (f != 'Custom') Get.back();
                  },
                );
              }).toList(),
            );
          }),

          const SizedBox(height: 20),
        ],
      ),
    ),
  );
}

// ── Pill chip ─────────────────────────────────────────────────────────────────

class _FilterPillChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final IconData? icon;

  const _FilterPillChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isSelected ? AppColors.primary : Colors.white;
    final fgColor = isSelected ? Colors.white : AppColors.subtitle;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 13, color: fgColor),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: fgColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}