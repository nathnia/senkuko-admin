// lib/features/products/pages/add_product_page.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:senkukoadmin/constant/app_colors.dart';
import 'package:senkukoadmin/features/products/controllers/product_controller.dart';
import 'package:senkukoadmin/features/products/controllers/product_variant_controller.dart';
import 'package:senkukoadmin/features/products/widgets/app_card.dart';
import 'package:senkukoadmin/constant/app_back_button.dart';
import 'package:senkukoadmin/features/products/widgets/product_form.dart';
import 'package:senkukoadmin/features/products/widgets/unsaved_changes_dialog.dart';
import 'package:senkukoadmin/features/products/widgets/variant_item_card.dart';
import 'package:senkukoadmin/routes/routes.dart';

class AddProductPage extends StatelessWidget {
  AddProductPage({super.key});

  final controller = Get.find<ProductController>();
  final variantC = Get.find<ProductVariantController>();
  late final _forms = ProductFormWidgets(controller);

  Future<bool> _confirmLeave() async {
    if (!controller.isDirty.value) return true;
    return UnsavedChangesDialog.show(title: 'Produk belum disimpan');
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.resetForAddProduct();
      variantC.initPriceControllers();
    });

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
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _forms.productImageGrid('', isAddMode: true),
              const SizedBox(height: 12),
              _forms.productForm(),
              const SizedBox(height: 12),
              _forms.variantForm(isEditMode: false),
              const SizedBox(height: 12),
              _variantList(),
              const SizedBox(height: 20),
              _submitButton(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _variantList() {
    return Obx(() {
      if (variantC.variantsTemp.isEmpty) return const SizedBox.shrink();

      return AppCard(
        title: 'VARIAN DITAMBAHKAN',
        child: Column(
          children: variantC.variantsTemp.asMap().entries.map((entry) {
            final i = entry.key;
            final v = entry.value;

            return VariantItemCard(
              variant: v,
              mode: VariantCardMode.add,
              index: i,
              onDelete: () => variantC.removeTempVariant(i, isEditMode: false),
            );
          }).toList(),
        ),
      );
    });
  }

  Widget _submitButton() {
    return Obx(
      () => SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            backgroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
            elevation: 0,
          ),
          onPressed:
              controller.isSubmitting.value || !controller.isDirty.value
                  ? null
                  : () async {
                      final success = await controller.createFullProduct();
                      if (success) {
                        Get.until((route) =>
                            route.settings.name == AppRoutes.product);
                      }
                    },
          child: controller.isSubmitting.value
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2),
                )
              : const Text(
                  'Simpan Produk',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white),
                ),
        ),
      ),
    );
  }
}