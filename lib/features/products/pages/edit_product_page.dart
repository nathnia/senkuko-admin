import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:senkukoadmin/constant/app_colors.dart';
import 'package:senkukoadmin/constant/currency_formatter.dart';
import 'package:senkukoadmin/features/products/controllers/product_controller.dart';
import 'package:senkukoadmin/features/products/controllers/product_variant_controller.dart';
import 'package:senkukoadmin/features/products/widgets/edit_variant_dialog.dart';
import 'package:senkukoadmin/features/products/widgets/product_form.dart';
import 'package:senkukoadmin/routes/routes.dart';

class EditProductPage extends StatelessWidget {
  EditProductPage({super.key});

  final controller = Get.find<ProductController>();
  late final _forms = ProductFormWidgets(controller);
  final variantC = Get.find<ProductVariantController>();

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

        if (!controller.isDirty.value) {
          Get.back();
          return;
        }

        final shouldPop = await Get.dialog<bool>(
          AlertDialog(
            title: const Text('Perubahan belum disimpan'),
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
        appBar: AppBar(
          title: const Text("Edit Produk"),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          actions: [
            Obx(
              () => Padding(
                padding: const EdgeInsets.only(right: 16),

                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                  onPressed:
                      controller.isSubmitting.value || !controller.isDirty.value
                      ? null
                      : () async {
                          await controller.updateFullProduct();
                          Get.until(
                            (route) => route.settings.name == AppRoutes.product,
                          );
                        },
                  child: controller.isSubmitting.value
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Simpan", style: TextStyle(fontSize: 14)),
                ),
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
                _forms.productImageGrid(productId),
                const SizedBox(height: 24),

                _forms.productForm(),
                const SizedBox(height: 24),

                const Text(
                  "Daftar Variant",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _existingVariantsList(),

                const SizedBox(height: 24),

                const Text(
                  "Tambah Variant Baru",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _forms.variantForm(isEditMode: true),
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
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Text(
            "Belum ada variant",
            style: TextStyle(color: Colors.grey),
          ),
        );
      }

      return Column(
        children: variantC.editVariantsTemp.asMap().entries.map((entry) {
          final i = entry.key;
          final v = entry.value;

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    v["name"] ?? "",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text("Stock: ${v["stock_qty"]} • ${v["unit_name"]}"),
                  if ((v["barcode"] ?? "").isNotEmpty)
                    Text("Barcode: ${v["barcode"]}"),
                  const SizedBox(height: 8),
                  const Text(
                    "Harga:",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  ...(v["prices"] as List? ?? []).map((p) {
                    final name =
                        variantC.priceListMaster
                            .firstWhereOrNull(
                              (pl) => pl.id == p["price_list_id"]?.toString(),
                            )
                            ?.name ??
                        p["price_list_id"];
                    return Text(
                      "- $name : ${CurrencyFormatter.format(p["price"]?.toString() ?? '0')}",
                      style: const TextStyle(fontSize: 13),
                    );
                  }),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        icon: const Icon(Icons.edit, size: 18),
                        label: const Text("Edit"),
                        onPressed: () {
                          variantC.prepareEditVariantDialog(i);
                          Get.dialog(
                            EditVariantDialog(index: i, c: variantC),
                            barrierDismissible: false,
                          );
                        },
                      ),
                      TextButton.icon(
                        icon: const Icon(
                          Icons.delete,
                          size: 18,
                          color: Colors.red,
                        ),
                        label: const Text(
                          "Hapus",
                          style: TextStyle(color: Colors.red),
                        ),
                        onPressed: () =>
                            variantC.removeTempVariant(i, isEditMode: true),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      );
    });
  }
}
