import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:senkukoadmin/constant/app_colors.dart';
import 'package:senkukoadmin/features/products/controllers/product_controller.dart';

const _sortOptions = [
  _SortOption('newest', 'Terbaru', Icons.schedule_rounded),
  _SortOption('oldest', 'Terlama', Icons.history_rounded),
  _SortOption('az', 'A – Z', Icons.sort_by_alpha_rounded),
  _SortOption('price_asc', 'Harga Termurah', Icons.arrow_downward_rounded),
  _SortOption('price_desc', 'Harga Termahal', Icons.arrow_upward_rounded),
  _SortOption('low_stock', 'Stok Terendah', Icons.inventory_2_outlined),
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
    backgroundColor: AppColors.background,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => Padding(
      padding: EdgeInsets.fromLTRB(
        20, 12, 20,
        MediaQuery.of(ctx).viewInsets.bottom + MediaQuery.of(ctx).padding.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                return _FilterPillChip(
                  label: opt.label,
                  icon: opt.icon,
                  isSelected: isSelected,
                  onTap: () => controller.selectedSort.value =
                      isSelected ? '' : opt.key,
                );
              }).toList(),
            )),

            const SizedBox(height: 20),
            const Divider(height: 1, color: Color(0xFFF0F0F0)),
            const SizedBox(height: 20),

            // ── Stock Status ──────────────────────────────────────────
            _SectionLabel('Status Stok'),
            const SizedBox(height: 10),
            Obx(() => Wrap(
              spacing: 8,
              children: [
                _FilterPillChip(
                  label: 'Stok Menipis',
                  icon: Icons.warning_amber_rounded,
                  isSelected: controller.showLowStockOnly.value,
                  onTap: () {
                    controller.showLowStockOnly.value =
                        !controller.showLowStockOnly.value;
                    if (controller.showLowStockOnly.value) {
                      controller.showOutOfStockOnly.value = false;
                    }
                  },
                ),
                _FilterPillChip(
                  label: 'Stok Habis',
                  icon: Icons.remove_circle_outline_rounded,
                  isSelected: controller.showOutOfStockOnly.value,
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
                    style: TextStyle(fontSize: 18, color: Colors.grey.shade400),
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
                      side: BorderSide(color: Colors.grey.shade600),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Reset',
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
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

// ── Pill chip — sama persis style AppFilterChips ──────────────────────────────
class _FilterPillChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterPillChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 12,
                color: isSelected ? Colors.white : Colors.grey.shade600,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? Colors.white : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
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

// ── Price field ───────────────────────────────────────────────────────────────
class _PriceField extends StatelessWidget {
  final TextEditingController controller;
  final String label;

  const _PriceField({required this.controller, required this.label});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          hintText: label,
          hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
          prefixText: 'Rp ',
          prefixStyle: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200, width: 0.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200, width: 0.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: AppColors.primary.withAlpha(80),
              width: 1,
            ),
          ),
        ),
      ),
    );
  }
}