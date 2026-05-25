import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:senkukoadmin/constant/app_colors.dart';
import 'package:senkukoadmin/features/products/controllers/product_controller.dart';

const _sortOptions = [
  _SortOption('newest', 'Terbaru', Icons.schedule_rounded),
  _SortOption('oldest', 'Terlama', Icons.history_rounded),
  _SortOption('az', 'A – Z', Icons.sort_by_alpha_rounded),
  _SortOption('price_asc', 'Harga ↑', Icons.arrow_upward_rounded),
  _SortOption('price_desc', 'Harga ↓', Icons.arrow_downward_rounded),
  _SortOption('low_stock', 'Stok Menipis', Icons.inventory_2_outlined),
];

class _SortOption {
  final String key;
  final String label;
  final IconData icon;
  const _SortOption(this.key, this.label, this.icon);
}

void showFilterSheet(BuildContext context, ProductController controller) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => Padding(
      padding: EdgeInsets.fromLTRB(
        20, 12, 20,
        MediaQuery.of(ctx).viewInsets.bottom + 28,
      ),
      child: SingleChildScrollView(
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

            // ── Sort ──────────────────────────────────────────────────
            _SectionLabel('Urutkan'),
            const SizedBox(height: 10),
            Obx(() => Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _sortOptions.map((opt) {
                final isSelected = controller.selectedSort.value == opt.key;
                return GestureDetector(
                  onTap: () => controller.selectedSort.value =
                      isSelected ? '' : opt.key,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : Colors.grey.shade200,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          opt.icon,
                          size: 14,
                          color: isSelected
                              ? Colors.white
                              : Colors.grey.shade600,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          opt.label,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: isSelected
                                ? Colors.white
                                : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            )),

            const SizedBox(height: 20),
            const Divider(height: 1, color: Color(0xFFF0F0F0)),
            const SizedBox(height: 20),

            // ── Stock Status ──────────────────────────────────────────
            _SectionLabel('Status Stok'),
            const SizedBox(height: 10),
            Obx(() => Row(
              children: [
                _StockChip(
                  label: 'Stok Menipis',
                  icon: Icons.warning_amber_rounded,
                  selected: controller.showLowStockOnly.value,
                  selectedBg: Colors.orange.shade50,
                  selectedBorder: Colors.orange.shade300,
                  selectedIcon: Colors.orange,
                  selectedText: Colors.orange.shade800,
                  onTap: () {
                    controller.showLowStockOnly.value =
                        !controller.showLowStockOnly.value;
                    if (controller.showLowStockOnly.value) {
                      controller.showOutOfStockOnly.value = false;
                    }
                  },
                ),
                const SizedBox(width: 8),
                _StockChip(
                  label: 'Stok Habis',
                  icon: Icons.remove_circle_outline_rounded,
                  selected: controller.showOutOfStockOnly.value,
                  selectedBg: Colors.red.shade50,
                  selectedBorder: Colors.red.shade300,
                  selectedIcon: Colors.red,
                  selectedText: Colors.red.shade800,
                  onTap: () {
                    controller.showOutOfStockOnly.value =
                        !controller.showOutOfStockOnly.value;
                    if (controller.showOutOfStockOnly.value) {
                      controller.showLowStockOnly.value = false;
                    }
                  },
                ),
              ],
            )),

            const SizedBox(height: 20),
            const Divider(height: 1, color: Color(0xFFF0F0F0)),
            const SizedBox(height: 20),

            // ── Price Range ───────────────────────────────────────────
            _SectionLabel('Rentang Harga'),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _PriceField(
                    controller: controller.minPriceC,
                    label: 'Minimum',
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    '–',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.shade400,
                    ),
                  ),
                ),
                Expanded(
                  child: _PriceField(
                    controller: controller.maxPriceC,
                    label: 'Maksimum',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ── Actions ───────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      controller.selectedSort.value = '';
                      controller.showLowStockOnly.value = false;
                      controller.showOutOfStockOnly.value = false;
                      controller.clearPriceRange();
                      Get.back();
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: Colors.grey.shade200),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Reset',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () {
                      controller.applyPriceFilter();
                      Get.back();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Terapkan',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

// ── Section label ─────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 13,
        color: Colors.grey.shade500,
        letterSpacing: 0.3,
      ),
    );
  }
}

// ── Stock chip ────────────────────────────────────────────────────────────────
class _StockChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final Color selectedBg;
  final Color selectedBorder;
  final Color selectedIcon;
  final Color selectedText;
  final VoidCallback onTap;

  const _StockChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.selectedBg,
    required this.selectedBorder,
    required this.selectedIcon,
    required this.selectedText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? selectedBg : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? selectedBorder : Colors.grey.shade200,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: selected ? selectedIcon : Colors.grey.shade500,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: selected ? selectedText : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Price field ───────────────────────────────────────────────────────────────
class _PriceField extends StatelessWidget {
  final TextEditingController controller;
  final String label;

  const _PriceField({required this.controller, required this.label});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
        prefixText: 'Rp ',
        prefixStyle: TextStyle(fontSize: 14, color: Colors.grey.shade500),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: AppColors.primary.withAlpha(80),
            width: 1.5,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
      ),
    );
  }
}