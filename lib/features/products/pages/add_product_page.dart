// lib/features/products/pages/add_product_page.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:senkukoadmin/constant/app_back_button.dart';
import 'package:senkukoadmin/constant/app_colors.dart';
import 'package:senkukoadmin/features/products/controllers/product_controller.dart';
import 'package:senkukoadmin/features/products/controllers/product_variant_controller.dart';
import 'package:senkukoadmin/constant/app_card.dart';
import 'package:senkukoadmin/features/products/widgets/product_image_section.dart';
import 'package:senkukoadmin/features/products/widgets/product_info_form.dart';
import 'package:senkukoadmin/constant/unsaved_changes_dialog.dart';
import 'package:senkukoadmin/features/products/widgets/variant_item_card.dart';
import 'package:senkukoadmin/routes/routes.dart';

class AddProductPage extends StatelessWidget {
  AddProductPage({super.key});

  final controller = Get.find<ProductController>();
  final variantC = Get.find<ProductVariantController>();

  Future<bool> _confirmLeave() async {
    if (!controller.isDirty.value) return true;
    return UnsavedChangesDialog.show(title: 'Produk belum disimpan');
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (await _confirmLeave()) {
          controller.resetForAddProduct();
          Get.back();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: AppBackButton(
            onTap: () async {
              if (await _confirmLeave()) {
                controller.resetForAddProduct();
                Get.back();
              }
            },
          ),
          title: const Text(
            'Tambah Produk',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          centerTitle: true,
        ),
        bottomNavigationBar: _submitButton(),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: Column(
            children: [
              ProductImageSection(
                controller: controller,
                productId: '',
                isAddMode: true,
              ),
              const SizedBox(height: 12),
              ProductInfoForm(controller: controller),
              const SizedBox(height: 12),
              _variantSection(),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _variantSection() {
    return AppCard(
      title: 'VARIAN',
      child: Column(
        children: [
          _addVariantRow(isEditMode: false),
          Obx(() {
            if (variantC.variantsTemp.isEmpty) return const SizedBox.shrink();
            return Column(
              children: variantC.variantsTemp.asMap().entries.map((entry) {
                final i = entry.key;
                final v = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: VariantItemCard(
                    variant: v,
                    mode: VariantCardMode.add,
                    index: i,
                    onDelete: () =>
                        variantC.removeTempVariant(i, isEditMode: false),
                  ),
                );
              }).toList(),
            );
          }),
        ],
      ),
    );
  }

  Widget _addVariantRow({required bool isEditMode}) {
    return GestureDetector(
      onTap: () => Get.toNamed(
        AppRoutes.variantForm,
        arguments: {'isEditMode': isEditMode},
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Tambah Varian',
                style: TextStyle(
                  color: AppColors.subtext,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(Icons.arrow_right_rounded, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  Widget _submitButton() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Obx(
          () => SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor: Colors.grey.shade300,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              onPressed: controller.isSubmitting.value || !controller.isDirty.value
                  ? null
                  : () async {
                      final success = await controller.createFullProduct();
                      if (success) {
                        Get.until(
                          (route) => route.settings.name == AppRoutes.product,
                        );
                      }
                    },
              child: controller.isSubmitting.value
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Simpan Produk',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}