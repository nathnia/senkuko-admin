import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:senkukoadmin/constant/app_colors.dart';
import 'package:senkukoadmin/features/products/product_controller.dart';

class EditProductPage extends StatelessWidget {
  EditProductPage({super.key});

  final controller = Get.find<ProductController>();

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

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text("Edit Produk"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
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
              _productForm(),
              const SizedBox(height: 24),

              const Text(
                "Daftar Variant",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _existingVariantsList(), // ← Daftar variant yang bisa diedit

              const SizedBox(height: 24),

              const Text(
                "Tambah Variant Baru",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _variantForm(), // ← Form tambah variant baru

              const SizedBox(height: 30),
              _submitButton(),
            ],
          ),
        );
      }),
    );
  }

  // ================= FORM PRODUK UTAMA =================
  Widget _productForm() {
    return _card(
      "Informasi Produk",
      Column(
        children: [
          _input(controller.nameC, "Nama Produk"),
          _input(controller.skuC, "SKU Code"),
          _input(controller.descC, "Deskripsi"),
          _input(controller.barcodeC, "Barcode"),
          const SizedBox(height: 12),
          _categorySelector(),
        ],
      ),
    );
  }

  Widget _categorySelector() {
    return Obx(() {
      final selected = controller.categoryList.firstWhereOrNull(
        (c) => c.id == controller.selectedCategoryId.value,
      );
      return GestureDetector(
        onTap: () => Get.snackbar(
          "Info",
          "Fitur pilih kategori belum diimplementasikan",
        ),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            selected?.name ?? "Pilih Kategori",
            style: const TextStyle(fontSize: 14),
          ),
        ),
      );
    });
  }

  // ================= DAFTAR VARIANT YANG SUDAH ADA (BISA DIEDIT) =================
  Widget _existingVariantsList() {
    return Obx(() {
      if (controller.editVariantsTemp.isEmpty) {
        return const Text("Belum ada variant");
      }

      return Column(
        children: controller.editVariantsTemp.asMap().entries.map((entry) {
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
                    v["name"],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text("Stock: ${v["stock_qty"]} • ${v["unit_name"]}"),
                  if (v["barcode"] != null) Text("Barcode: ${v["barcode"]}"),

                  const SizedBox(height: 8),

                  const Text(
                    "Harga:",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),

                  ...(v["prices"] as List? ?? []).map((p) {
                    final priceListName =
                        controller.priceListMaster
                            .firstWhereOrNull(
                              (pl) => pl.id == p["price_list_id"]?.toString(),
                            )
                            ?.name ??
                        "Harga ${p["price_list_id"]}";

                    return Text(
                      "- $priceListName : Rp ${p["price"]}",
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
                        onPressed: () => controller.openEditVariantPopup(i),
                      ),
                      TextButton.icon(
                        icon: const Icon(
                          Icons.delete,
                          size: 18,
                          color: Colors.red,
                        ),
                        label: const Text("Hapus"),
                        onPressed: () => controller.removeTempVariant(i),
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

  // ================= FORM TAMBAH VARIANT BARU =================
  Widget _variantForm() {
    return _card(
      "Tambah Variant Baru",
      Column(
        children: [
          _input(controller.variantNameC, "Nama Variant"),
          _input(controller.variantStockC, "Stock"),
          _input(controller.variantBarcodeC, "Barcode (opsional)"),
          const SizedBox(height: 12),
          _unitDropdown(),
          const SizedBox(height: 12),
          _priceMatrix(),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: controller.addVariantFromForm,
            child: const Text("Tambah Variant"),
          ),
        ],
      ),
    );
  }

  // ================= SUBMIT =================
Widget _submitButton() {
  return Obx(() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          backgroundColor: AppColors.primary,
        ),
        onPressed: controller.isSubmitting.value
            ? null
            : () async {
                print("Tombol SIMPAN PERUBAHAN di halaman Edit ditekan");
                await controller.updateFullProduct();
              },
        child: controller.isSubmitting.value
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text("Simpan Perubahan", style: TextStyle(fontSize: 16)),
      ),
    );
  });
}
  // Helper widgets (sama seperti sebelumnya)
  Widget _card(String title, Widget child) {
    return Container(
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _input(TextEditingController c, String hint) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: c,
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: Colors.grey.shade100,
          border: const OutlineInputBorder(borderSide: BorderSide.none),
        ),
      ),
    );
  }

  Widget _unitDropdown() {
    return GestureDetector(
      onTap: () => Get.snackbar("Info", "Fitur unit sedang dikembangkan"),
      child: Obx(() {
        final selected = controller.unitList.firstWhereOrNull(
          (u) => u.id == controller.selectedUnitId.value,
        );
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            selected != null
                ? "${selected.name} (${selected.symbol})"
                : "Pilih Unit",
          ),
        );
      }),
    );
  }

  Widget _priceMatrix() {
    return Obx(() {
      return Column(
        children: controller.priceListMaster.map((p) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                SizedBox(width: 100, child: Text("[${p.name}]")),
                Expanded(
                  child: TextField(
                    controller: controller.priceControllers[p.id],
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      hintText: "Harga",
                      filled: true,
                      fillColor: Colors.grey,
                      border: OutlineInputBorder(borderSide: BorderSide.none),
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      );
    });
  }
}
