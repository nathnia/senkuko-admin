import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:senkukoadmin/features/products/product_controller.dart';

class AddProductPage extends StatelessWidget {
  AddProductPage({super.key});

  final controller = Get.find<ProductController>();

  @override
  Widget build(BuildContext context) {
    controller.initPriceControllers(controller.priceListMaster);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.resetForAddProduct();
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(title: const Text("Tambah Produk")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _productForm(),
            const SizedBox(height: 16),
            _variantSection(),
            const SizedBox(height: 20),
            _submitButton(),
          ],
        ),
      ),
    );
  }

  // ================= PRODUCT =================
  Widget _productForm() {
    return _card(
      "Produk",
      Column(
        children: [
          _input(controller.nameC, "Nama Produk"),
          _input(controller.skuC, "SKU"),
          _input(controller.descC, "Deskripsi"),
          _input(controller.barcodeC, "Barcode"),
          const SizedBox(height: 10),
          _category(),
        ],
      ),
    );
  }

  Widget _category() {
    return GestureDetector(
      onTap: () => _openCategoryPopup(),
      child: Obx(() {
        final selected = controller.categoryList.firstWhereOrNull(
          (c) => c.id == controller.selectedCategoryId.value,
        );

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            selected?.name ?? "Pilih Category",
            style: const TextStyle(fontSize: 14),
          ),
        );
      }),
    );
  }

  void _openCategoryPopup() {
    final TextEditingController newCategoryC = TextEditingController();

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(16),
        height: 400,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          children: [
            const Text(
              "Pilih / Tambah Category",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            // ================= LIST CATEGORY =================
            Expanded(
              child: Obx(() {
                return ListView(
                  children: controller.categoryList.map((c) {
                    return ListTile(
                      title: Text(c.name),
                      onTap: () {
                        controller.selectedCategoryId.value = c.id;
                        Get.back();
                      },
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _confirmDeleteCategory(c.id),
                      ),
                    );
                  }).toList(),
                );
              }),
            ),

            const Divider(),

            // ================= TAMBAH CATEGORY =================
            TextField(
              controller: newCategoryC,
              decoration: const InputDecoration(
                hintText: "Tambah Category Baru",
              ),
            ),

            const SizedBox(height: 10),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  if (newCategoryC.text.isEmpty) return;

                  final newId = await controller.createCategory(
                    newCategoryC.text,
                  );

                  if (newId != null) {
                    await controller.fetchCategories();

                    controller.selectedCategoryId.value = newId;

                    Get.back();
                  }
                },
                child: const Text("Tambah"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= VARIANT =================
  Widget _variantSection() {
    return _card(
      "Variant",
      Column(
        children: [
          _input(controller.variantNameC, "Nama Variant"),
          _input(controller.variantStockC, "Stock"),
          _input(controller.variantBarcodeC, "Barcode (opsional)"),

          const SizedBox(height: 10),

          _unitDropdown(),

          const SizedBox(height: 10),

          _priceMatrix(),

          const SizedBox(height: 10),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: controller.addVariantFromForm,
              child: const Text("Tambah Variant"),
            ),
          ),

          const SizedBox(height: 10),
          _variantList(),
        ],
      ),
    );
  }

  void _confirmDeleteCategory(String id) {
    Get.defaultDialog(
      title: "Hapus Category",
      middleText: "Yakin mau hapus?",
      textConfirm: "Hapus",
      textCancel: "Batal",
      confirmTextColor: Colors.white,
      onConfirm: () async {
        Get.back();
        await controller.deleteCategory(id);
      },
    );
  }

  Widget _unitDropdown() {
    return GestureDetector(
      onTap: _openUnitPopup,
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
                    decoration: InputDecoration(
                      hintText: "Harga",
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: const OutlineInputBorder(
                        borderSide: BorderSide.none,
                      ),
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

  Widget _variantList() {
    return Obx(() {
      if (controller.variantsTemp.isEmpty) {
        return const Text("Belum ada variant");
      }

      return Column(
        children: controller.variantsTemp.map((v) {
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(10),
            color: Colors.grey.shade100,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  v["name"],
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text("Stock: ${v["stock_qty"]}"),
                Text("Unit: ${v["unit_name"]}"),
                if (v["barcode"] != null) Text("Barcode: ${v["barcode"]}"),
                ...((v["prices"] as List).map((p) {
                  return Text("- ${p["price_list_id"]}: ${p["price"]}");
                })),
              ],
            ),
          );
        }).toList(),
      );
    });
  }

  Widget _submitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          if (controller.isEditMode.value) {
            controller.updateFullProduct();
          } else {
            controller.createFullProduct();
          }
        },
        child: const Text("Simpan Produk"),
      ),
    );
  }

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

  Widget _input(TextEditingController c, String h) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: c,
        decoration: InputDecoration(
          hintText: h,
          filled: true,
          fillColor: Colors.grey.shade100,
          border: const OutlineInputBorder(borderSide: BorderSide.none),
        ),
      ),
    );
  }

  void _confirmDeleteUnit(String id) {
    Get.defaultDialog(
      title: "Hapus Unit",
      middleText: "Yakin mau hapus unit ini?",
      textConfirm: "Hapus",
      textCancel: "Batal",
      confirmTextColor: Colors.white,
      onConfirm: () async {
        Get.back();
        await controller.deleteUnit(id);
      },
    );
  }

  void _openUnitPopup() {
    final nameC = TextEditingController();
    final symbolC = TextEditingController();

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(16),
        height: 400,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          children: [
            const Text(
              "Pilih / Tambah Unit",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            // ===== LIST UNIT =====
            Expanded(
              child: Obx(() {
                return ListView(
                  children: controller.unitList.map((u) {
                    return ListTile(
                      title: Text("${u.name} (${u.symbol})"),

                      // SELECT
                      onTap: () {
                        controller.selectedUnitId.value = u.id;
                        Get.back();
                      },

                      // DELETE BUTTON
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _confirmDeleteUnit(u.id),
                      ),
                    );
                  }).toList(),
                );
              }),
            ),

            const Divider(),

            // ===== ADD UNIT =====
            TextField(
              controller: nameC,
              decoration: const InputDecoration(hintText: "Nama Unit"),
            ),
            TextField(
              controller: symbolC,
              decoration: const InputDecoration(hintText: "Symbol (pcs, box)"),
            ),

            const SizedBox(height: 10),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  if (nameC.text.isEmpty || symbolC.text.isEmpty) return;

                  final newId = await controller.createUnit(
                    nameC.text,
                    symbolC.text,
                  );

                  if (newId != null) {
                    await controller.fetchUnits();
                    controller.selectedUnitId.value = newId;
                    Get.back();
                  }
                },
                child: const Text("Tambah"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
