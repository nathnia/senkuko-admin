import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:senkukoadmin/constant/app_colors.dart';
import 'package:senkukoadmin/constant/currency_formatter.dart';
import 'package:senkukoadmin/features/products/controllers/product_controller.dart';
import 'package:senkukoadmin/features/products/controllers/product_variant_controller.dart';
import 'package:senkukoadmin/features/products/widgets/product_form.dart';
import 'package:senkukoadmin/routes/routes.dart';

class AddProductPage extends StatelessWidget {
  AddProductPage({super.key});

  final controller = Get.find<ProductController>();
  final variantC = Get.find<ProductVariantController>();
  late final _forms = ProductFormWidgets(controller);

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

        if (!controller.isDirty.value) {
          Get.back();
          return;
        }

        final shouldPop = await Get.dialog<bool>(
          AlertDialog(
            title: const Text('Produk belum disimpan'),
            content: const Text('Yakin mau keluar? Perubahan akan hilang.'),
            actions: [
              TextButton(
                onPressed: () => Get.back(result: false),
                child: const Text('Tetap di sini'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => Get.back(result: true),
                child: const Text(
                  'Keluar',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        );

        if (shouldPop == true) {
          controller.resetForAddProduct();
          Get.back();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F6FA),
        appBar: AppBar(title: const Text("Tambah Produk")),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _forms.productImageGrid('', isAddMode: true),
              const SizedBox(height: 16),
              _forms.productForm(),
              const SizedBox(height: 16),
              _forms.variantForm(isEditMode: false),
              const SizedBox(height: 16),
              _variantList(),
              const SizedBox(height: 20),
              _submitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _variantList() {
    return Obx(() {
      if (variantC.variantsTemp.isEmpty) {
        return const SizedBox.shrink();
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Variant yang ditambahkan:",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...variantC.variantsTemp.asMap().entries.map((entry) {
            final i = entry.key;
            final v = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          v["name"],
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text("Stock: ${v["stock_qty"]} • ${v["unit_name"]}"),
                        if (v["barcode"] != null)
                          Text("Barcode: ${v["barcode"]}"),
                        ...(v["prices"] as List).map(
                          (p) => Text(CurrencyFormatter.format(p["price"])),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () =>
                        variantC.removeTempVariant(i, isEditMode: false),
                  ),
                ],
              ),
            );
          }),
        ],
      );
    });
  }

  // Di add page
  Widget _submitButton() {
    return Obx(
      () => SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            backgroundColor: AppColors.primary,
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
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text("Simpan Produk", style: TextStyle(fontSize: 16)),
        ),
      ),
    );
  }
}
