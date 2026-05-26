// lib/features/products/pages/edit_product_page.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:senkukoadmin/constant/app_back_button.dart';
import 'package:senkukoadmin/constant/app_colors.dart';
import 'package:senkukoadmin/features/products/controllers/product_controller.dart';
import 'package:senkukoadmin/features/products/controllers/product_image_controller.dart';
import 'package:senkukoadmin/features/products/controllers/product_variant_controller.dart';
import 'package:senkukoadmin/features/products/widgets/app_card.dart';
import 'package:senkukoadmin/features/products/widgets/product_image_section.dart';
import 'package:senkukoadmin/features/products/widgets/product_info_form.dart';
import 'package:senkukoadmin/features/products/widgets/save_button.dart';
import 'package:senkukoadmin/features/products/widgets/unsaved_changes_dialog.dart';
import 'package:senkukoadmin/features/products/widgets/variant_item_card.dart';
import 'package:senkukoadmin/routes/routes.dart';

class EditProductPage extends StatelessWidget {
  EditProductPage({super.key});

  final controller = Get.find<ProductController>();
  final variantC = Get.find<ProductVariantController>();
  final imageC = Get.find<ProductImageController>();

  Future<bool> _confirmLeave() async {
    if (!controller.isDirty.value) return true;
    return UnsavedChangesDialog.show();
  }

  @override
  Widget build(BuildContext context) {
    final String? productId = Get.arguments as String?;

    if (productId == null) {
      return const Scaffold(
        body: Center(child: Text('ID Produk tidak ditemukan')),
      );
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.loadEditData(productId);
    });

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (await _confirmLeave()) Get.back();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: AppBackButton(
            onTap: () async {
              if (await _confirmLeave()) Get.back();
            },
          ),
          title: const Text(
            'Edit Produk',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          centerTitle: true,
          actions: [
            Obx(
              () => AppSaveButton(
                isLoading: controller.isSubmitting.value,
                isDisabled: !controller.isDirty.value,
                onTap: () async {
                  await controller.updateFullProduct();
                  await controller.loadProductDetail(productId);
                  Get.back();
                },
              ),
            ),
          ],
        ),
        body: Obx(() {
          if (controller.isLoadingDetail.value) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ProductImageSection(
                  controller: controller,
                  productId: productId,
                ),
                const SizedBox(height: 12),
                ProductInfoForm(controller: controller),
                const SizedBox(height: 12),
                _variantSection(productId),
                const SizedBox(height: 16),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _variantSection(String productId) {
    return AppCard(
      title: 'VARIAN',
      child: Column(
        children: [
          Obx(() {
            if (variantC.editVariantsTemp.isEmpty) {
              return const SizedBox.shrink();
            }
            return Column(
              children: variantC.editVariantsTemp.asMap().entries.map((entry) {
                final i = entry.key;
                final v = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: VariantItemCard(
                    variant: v,
                    mode: VariantCardMode.edit,
                    index: i,
                    onEdit: () {
                      variantC.prepareEditVariant(i);
                      Get.toNamed(
                        AppRoutes.variantForm,
                        arguments: {'index': i, 'isEditMode': true},
                      );
                    },
                    onDelete: () {
                      controller.isDirty.value = true;
                      variantC.deleteVariant(i, isEditMode: true);
                    },
                  ),
                );
              }).toList(),
            );
          }),
          _addVariantRow(isEditMode: true),
        ],
      ),
    );
  }

  Widget _addVariantRow({required bool isEditMode}) {
    return GestureDetector(
      onTap: () {
        variantC.clearVariantForm();
        Get.toNamed(
          AppRoutes.variantForm,
          arguments: {'isEditMode': isEditMode},
        );
      },
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
                'Tambah Varian Baru',
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
}