// lib/features/products/pages/edit_product_page.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:senkukoadmin/constant/app_colors.dart';
import 'package:senkukoadmin/features/products/controllers/product_controller.dart';
import 'package:senkukoadmin/features/products/controllers/product_image_controller.dart';
import 'package:senkukoadmin/features/products/controllers/product_variant_controller.dart';
import 'package:senkukoadmin/features/products/widgets/app_card.dart';
import 'package:senkukoadmin/constant/app_back_button.dart';
import 'package:senkukoadmin/features/products/widgets/product_form.dart';
import 'package:senkukoadmin/features/products/widgets/save_button.dart';
import 'package:senkukoadmin/features/products/widgets/unsaved_changes_dialog.dart';
import 'package:senkukoadmin/features/products/widgets/variant_item_card.dart';
import 'package:senkukoadmin/routes/routes.dart';

class EditProductPage extends StatelessWidget {
  EditProductPage({super.key});

  final controller = Get.find<ProductController>();
  final variantC = Get.find<ProductVariantController>();
  final imageC = Get.find<ProductImageController>();
  late final _forms = ProductFormWidgets(controller);

  Future<bool> _confirmLeave() async {
    if (!controller.isDirty.value) return true;
    return UnsavedChangesDialog.show();
  }

  @override
  Widget build(BuildContext context) {
    final String? productId = Get.arguments as String?;

    if (productId == null) {
      return const Scaffold(
        body: Center(child: Text("ID Produk tidak ditemukan")),
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
            Obx(() => AppSaveButton(
                  isLoading: controller.isSubmitting.value,
                  isDisabled: !controller.isDirty.value,
                  onTap: () async {
                    await controller.updateFullProduct();
                    Get.back();
                    Get.snackbar(
                      'Sukses',
                      'Produk berhasil diupdate',
                      backgroundColor: Colors.green,
                      colorText: Colors.white,
                    );
                  },
                )),
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
                _forms.productImageGrid(productId),
                const SizedBox(height: 12),
                _forms.productForm(),
                const SizedBox(height: 12),
                // FIX: form tambah varian dulu, baru list varian di bawahnya
                _forms.variantForm(isEditMode: true),
                const SizedBox(height: 12),
                _existingVariantsList(),
                const SizedBox(height: 16),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _existingVariantsList() {
    return Obx(() {
      if (variantC.editVariantsTemp.isEmpty) {
        return AppCard(
          child: Center(
            child: Text(
              'Belum ada varian',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
            ),
          ),
        );
      }

      return AppCard(
        title: 'DAFTAR VARIAN',
        child: Column(
          children: variantC.editVariantsTemp.asMap().entries.map((entry) {
            final i = entry.key;
            final v = entry.value;

            return VariantItemCard(
              variant: v,
              mode: VariantCardMode.edit,
              index: i,
              onEdit: () {
                variantC.prepareEditVariant(i);
                Get.toNamed(
                  AppRoutes.editProductVariant,
                  arguments: {'index': i},
                );
              },
              onDelete: () =>
                  variantC.removeTempVariant(i, isEditMode: true),
            );
          }).toList(),
        ),
      );
    });
  }
}