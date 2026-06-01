// FILE: lib/features/products/widgets/product_info_form.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:senkukoadmin/constant/app_colors.dart';
import 'package:senkukoadmin/constant/app_textfield.dart';
import 'package:senkukoadmin/features/products/controllers/category_controller.dart';
import 'package:senkukoadmin/features/products/controllers/product_controller.dart';
import 'package:senkukoadmin/constant/app_card.dart';
import 'package:senkukoadmin/features/products/widgets/category_picker_sheet.dart';

class ProductInfoForm extends StatelessWidget {
  final ProductController controller;
  const ProductInfoForm({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      title: 'INFORMASI PRODUK',
      child: Column(
        children: [
          AppTextField(
            label: 'Nama Produk',
            hint: 'cth: Indomie Goreng',
            controller: controller.nameC,
          ),
          AppTextField(
            label: 'SKU Code',
            hint: 'cth: PRD-001',
            controller: controller.skuC,
          ),
          AppTextField(
            label: 'Deskripsi',
            hint: 'Tambahkan Deskripsi',
            controller: controller.descC,
            maxLines: 3,
          ),
          AppTextField(
            label: 'Barcode',
            hint: 'cth: 8999999004001',
            controller: controller.barcodeC,
          ),
          const SizedBox(height: 4),
          _CategorySelector(controller: controller),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// CATEGORY SELECTOR — trigger button only, reuses CategoryPickerSheet
// ═══════════════════════════════════════════════════════════════
class _CategorySelector extends StatelessWidget {
  final ProductController controller;
  const _CategorySelector({required this.controller});

  CategoryController get _categoryC => Get.find<CategoryController>();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Kategori',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.subtext,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 5),
        Obx(() {
          final selected = _categoryC.categoryList.firstWhereOrNull(
            (c) => c.id == controller.selectedCategoryId.value,
          );
          final displayName = selected == null
              ? 'Pilih Kategori'
              : selected.parentName != null
                  ? '${selected.parentName} › ${selected.name}'
                  : selected.name;

          return GestureDetector(
            onTap: () async {
              final picked = await CategoryPickerSheet.show(context, showManageLink: true);
              if (picked == null) return;
              controller.selectedCategoryId.value = picked.id;
              controller.checkDirty();
            },
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      displayName,
                      style: TextStyle(
                        fontSize: 14,
                        color: selected != null
                            ? Colors.black87
                            : AppColors.subtext,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.arrow_drop_down_rounded,
                    color: Colors.grey.shade400,
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}