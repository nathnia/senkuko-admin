import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:senkukoadmin/constant/app_colors.dart';
import 'package:senkukoadmin/constant/app_dialog.dart';
import 'package:senkukoadmin/constant/app_textfield.dart';
import 'package:senkukoadmin/features/products/controllers/product_controller.dart';
import 'package:senkukoadmin/features/products/widgets/app_card.dart';

class ProductInfoForm {
  final ProductController controller;

  ProductInfoForm(this.controller);

  // ================= PRODUCT FORM =================
  Widget productForm() {
    return AppCard(
      title: 'INFORMASI PRODUK',
      child: Column(
        children: [
          AppTextField(
            hint: 'Nama Produk',
            controller: controller.nameC,
            onChanged: (_) => controller.isDirty.value = true,
          ),

          AppTextField(
            hint: 'SKU Code',
            controller: controller.skuC,
            onChanged: (_) => controller.isDirty.value = true,
          ),

          AppTextField(
            hint: 'Deskripsi',
            controller: controller.descC,
            maxLines: 3,
            onChanged: (_) => controller.isDirty.value = true,
          ),

          AppTextField(
            hint: 'Barcode',
            controller: controller.barcodeC,
            onChanged: (_) => controller.isDirty.value = true,
          ),
          const SizedBox(height: 4),
          categorySelector(),
        ],
      ),
    );
  }

  // ================= CATEGORY SELECTOR =================
  Widget categorySelector() {
    return Obx(() {
      final selected = controller.categoryList.firstWhereOrNull(
        (c) => c.id == controller.selectedCategoryId.value,
      );
      return GestureDetector(
        onTap: () => openCategoryPopup(),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  selected?.name ?? 'Pilih Kategori',
                  style: TextStyle(
                    fontSize: 14,
                    color: selected != null
                        ? Colors.black87
                        : Colors.grey.shade500,
                  ),
                ),
              ),
              Icon(Icons.arrow_drop_down_rounded, color: Colors.grey.shade400),
            ],
          ),
        ),
      );
    });
  }

  void openCategoryPopup() {
    final newCategoryC = TextEditingController();
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(16),
        height: 420,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            _bottomSheetHandle(),
            const SizedBox(height: 14),
            const Text(
              'Pilih / Tambah Kategori',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Obx(
                () => ListView(
                  children: controller.categoryList.map((c) {
                    return ListTile(
                      title: Text(c.name, style: const TextStyle(fontSize: 14)),
                      trailing: GestureDetector(
                        onTap: () => _confirmDeleteCategory(c.id),
                        child: _deleteIconBox(),
                      ),
                      onTap: () {
                        controller.selectedCategoryId.value = c.id;
                        controller.isDirty.value = true;
                        Get.back();
                      },
                    );
                  }).toList(),
                ),
              ),
            ),
            const Divider(),
            AppTextField(
              hint: 'Nama kategori baru',
              controller: newCategoryC,
              onChanged: (_) => controller.isDirty.value = true,
            ),
            const SizedBox(height: 10),
            _primaryButton(
              label: 'Tambah',
              onPressed: () async {
                if (newCategoryC.text.trim().isEmpty) return;
                final newId = await controller.createCategory(
                  newCategoryC.text.trim(),
                );
                if (newId != null) {
                  await controller.fetchCategories();
                  controller.selectedCategoryId.value = newId;
                  Get.back();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteCategory(String id) async {
    final confirm = await AppDialog.confirm(
      title: 'Hapus Kategori',
      content: 'Yakin mau hapus kategori ini?',
    );
    if (confirm) await controller.deleteCategory(id);
  }

  // ================= PRIVATE HELPERS =================
  Widget _bottomSheetHandle() {
    return Container(
      width: 36,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _deleteIconBox() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.delete_outline_rounded,
        size: 15,
        color: Colors.red.shade400,
      ),
    );
  }

  Widget _primaryButton({
    required String label,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12),
          elevation: 0,
        ),
        onPressed: onPressed,
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
