import 'package:flutter/material.dart';
import 'package:senkukoadmin/constant/app_colors.dart';

/// A single chip item used inside [AppFilterChips].
class FilterChipItem {
  final String label;
  final IconData? icon;

  const FilterChipItem({required this.label, this.icon});
}

/// A reusable horizontal scrollable filter chip row.
///
/// Handles its own "active" highlight. Pass the currently selected label
/// via [selectedLabel] and react to taps with [onChipTap].
///
/// Usage:
/// ```dart
/// AppFilterChips(
///   items: [
///     FilterChipItem(label: 'Semua'),
///     FilterChipItem(label: 'Hari ini'),
///     FilterChipItem(label: 'Custom', icon: Icons.date_range_outlined),
///   ],
///   selectedLabel: controller.selectedQuickDate.value,
///   onChipTap: (label) async {
///     if (label == 'Custom') {
///       await controller.pickDateRange(context);
///     } else {
///       controller.updateQuickDate(label);
///     }
///   },
/// )
/// ```
class AppFilterChips extends StatelessWidget {
  final List<FilterChipItem> items;
  final String selectedLabel;
  final void Function(String label) onChipTap;

  /// Optional: override the displayed label for the selected chip.
  /// Useful for "Custom" date range that shows the selected range instead.
  final String? selectedLabelOverride;

  const AppFilterChips({
    super.key,
    required this.items,
    required this.selectedLabel,
    required this.onChipTap,
    this.selectedLabelOverride,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10),
      color: AppColors.background,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 16),
        child: Row(
          children: items.map((item) {
            final isSelected = selectedLabel == item.label;
            final displayLabel =
                (isSelected && selectedLabelOverride != null)
                    ? selectedLabelOverride!
                    : item.label;

            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => onChipTap(item.label),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : Colors.grey.shade300,
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (item.icon != null) ...[
                        Icon(
                          item.icon,
                          size: 12,
                          color: isSelected
                              ? Colors.white
                              : Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                      ],
                      Text(
                        displayLabel,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w500,
                          color: isSelected ? Colors.white : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}