// lib/features/products/pages/edit_product_page.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:senkukoadmin/constant/app_back_button.dart';
import 'package:senkukoadmin/constant/app_colors.dart';
import 'package:senkukoadmin/features/products/controllers/product_controller.dart';
import 'package:senkukoadmin/features/products/controllers/product_image_controller.dart';
import 'package:senkukoadmin/features/products/controllers/product_variant_controller.dart';
import 'package:senkukoadmin/constant/app_card.dart';
import 'package:senkukoadmin/features/products/widgets/product_image_section.dart';
import 'package:senkukoadmin/features/products/widgets/product_info_form.dart';
import 'package:senkukoadmin/constant/unsaved_changes_dialog.dart';
import 'package:senkukoadmin/features/products/widgets/variant_item_card.dart';
import 'package:senkukoadmin/routes/routes.dart';

class EditProductPage extends StatefulWidget {
  const EditProductPage({super.key});

  @override
  State<EditProductPage> createState() => _EditProductPageState();
}

class _EditProductPageState extends State<EditProductPage> {
  final controller = Get.find<ProductController>();
  final variantC = Get.find<ProductVariantController>();
  final imageC = Get.find<ProductImageController>();

  String? _productId;

  @override
  void initState() {
    super.initState();
    _productId = Get.arguments as String?;
    if (_productId != null) {
      // initState dipanggil SEKALI — aman, tidak ada double-load
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.loadEditData(_productId!);
      });
    }
  }

  Future<bool> _confirmLeave() async {
    if (!controller.isDirty.value) return true;
    return UnsavedChangesDialog.show();
  }

  @override
  Widget build(BuildContext context) {
    if (_productId == null) {
      return const Scaffold(
        body: Center(child: Text('ID Produk tidak ditemukan')),
      );
    }

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
        ),
        bottomNavigationBar: SafeArea(
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
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  onPressed: controller.isSubmitting.value || !controller.isDirty.value
                      ? null
                      : () async {
                          final success = await controller.updateFullProduct();
                          if (success) {
                            await controller.loadProductDetail(_productId!);
                            Get.back();
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
                          'Simpan Perubahan',
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
        ),
        body: Obx(() {
          if (controller.isLoadingDetail.value) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ProductImageSection(
                  controller: controller,
                  productId: _productId!,
                ),
                const SizedBox(height: 12),
                ProductInfoForm(controller: controller),
                const SizedBox(height: 12),
                _variantSection(_productId!),
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
          _addVariantRow(),
        ],
      ),
    );
  }

  Widget _addVariantRow() {
    return GestureDetector(
      onTap: () {
        variantC.clearVariantForm();
        Get.toNamed(AppRoutes.variantForm, arguments: {'isEditMode': true});
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