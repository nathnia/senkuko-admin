// lib/features/products/widgets/product_form_widgets.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:senkukoadmin/constant/currency_formatter.dart';
import 'package:senkukoadmin/features/products/controllers/product_image_controller.dart';
import 'package:senkukoadmin/features/products/controllers/product_variant_controller.dart';
import 'package:senkukoadmin/features/products/models/product_image_model.dart';
import 'package:senkukoadmin/features/products/controllers/product_controller.dart';

class ProductFormWidgets {
  final ProductController controller;
  final variantC = Get.find<ProductVariantController>();
  final imageC = Get.find<ProductImageController>();

  ProductFormWidgets(this.controller);
  // ================= PRODUCT IMAGE GRID =================
  Widget productImageGrid(String productId, {bool isAddMode = false}) {
    return Obx(() {
      final images = imageC.getImagesForProduct(productId);
      final isUploading = imageC.isUploadingImage.value;
      final canAddMore = images.length < ProductImageController.maxImages;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Foto Produk',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 8),
              Text(
                '${images.length}/${ProductImageController.maxImages}',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 110,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                // Gambar yang sudah ada
                ...images.asMap().entries.map((entry) {
                  final int index = entry.key;
                  final ProductImageData image = entry.value;
                  return _imageThumb(
                    imageUrl: image.imageUrl,
                    isPrimary: image.isPrimary,
                    onDelete: () async {
                      final confirm =
                          await Get.dialog<bool>(
                            barrierDismissible: false,
                            AlertDialog(
                              title: const Text("Hapus Gambar"),
                              content: const Text(
                                "Yakin ingin menghapus gambar ini?",
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Get.back(result: false),
                                  child: const Text("Batal"),
                                ),
                                TextButton(
                                  onPressed: () => Get.back(result: true),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.red,
                                  ),
                                  child: const Text("Hapus"),
                                ),
                              ],
                            ),
                          ) ??
                          false;

                      if (confirm) {
                        imageC.deleteProductImage(productId, image.id, index);
                      }
                    },
                    isLoading: isUploading,
                  );
                }),
                // Tombol Tambah Gambar
                if (canAddMore)
                  _addImageButton(
                    productId: productId,
                    isUploading: isUploading,
                    isAddMode: isAddMode,
                  ),
              ],
            ),
          ),
          if (images.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'Tap ✕ untuk hapus • Gambar pertama = foto utama',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
            ),
        ],
      );
    });
  }

  void _showImageSourcePicker(String productId) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Obx(
              () => Text(
                'Upload Gambar (${imageC.getImagesForProduct(productId).length}/${ProductImageController.maxImages})',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Pilih dari Galeri'),
              onTap: () {
                Get.back();
                imageC.pickAndUploadImage(productId);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Ambil dari Kamera'),
              onTap: () {
                Get.back();
                // camera logic
              },
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  // ================= IMAGE THUMBNAIL =================
  Widget _imageThumb({
    required String imageUrl,
    required bool isPrimary,
    required VoidCallback onDelete,
    required bool isLoading,
  }) {
    if (imageUrl.isEmpty) {
      return Container(
        width: 100,
        height: 100,
        color: Colors.grey.shade200,
        child: const Icon(Icons.broken_image, color: Colors.red),
      );
    }
    return Container(
      width: 100,
      height: 100,
      margin: const EdgeInsets.only(right: 8),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              imageUrl,
              width: 100,
              height: 100,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) {
                  debugPrint("✅ Image loaded successfully: $imageUrl");
                  return child;
                }
                return const Center(child: CircularProgressIndicator());
              },
              errorBuilder: (context, error, stackTrace) {
                debugPrint("❌ FAILED to load image: $imageUrl");
                debugPrint(" Error: $error");
                return Container(
                  width: 100,
                  height: 100,
                  color: Colors.grey.shade200,
                  child: const Icon(
                    Icons.broken_image,
                    color: Colors.red,
                    size: 32,
                  ),
                );
              },
            ),
          ),
          if (isPrimary)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(60),
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(10),
                  ),
                ),
                child: const Text(
                  'Utama',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 10),
                ),
              ),
            ),
          // ✅ PERBAIKI INI
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: isLoading
                  ? null
                  : () {
                      onDelete();
                    },
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: isLoading ? Colors.grey : Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 14, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _addImageButton({
    required String productId,
    required bool isUploading,
    required bool isAddMode,
  }) {
    return GestureDetector(
      onTap: isUploading
          ? null
          : () {
              if (isAddMode) {
                imageC.pickImageForNewProduct();
              } else {
                _showImageSourcePicker(productId);
              }
            },
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Colors.grey.shade300,
            style: BorderStyle.solid,
          ),
        ),
        child: isUploading
            ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
            : const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_photo_alternate_outlined,
                    size: 28,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Tambah',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
      ),
    );
  }

  // ================= SHARED: PRODUCT FORM =================
  Widget productForm() {
    return _card(
      "Informasi Produk",
      Column(
        children: [
          _input(controller.nameC, "Nama Produk"),
          _input(controller.skuC, "SKU Code"),
          _input(controller.descC, "Deskripsi"),
          _input(controller.barcodeC, "Barcode"),
          const SizedBox(height: 12),
          categorySelector(),
        ],
      ),
    );
  }

  // ================= SHARED: CATEGORY =================
  Widget categorySelector() {
    return Obx(() {
      final selected = controller.categoryList.firstWhereOrNull(
        (c) => c.id == controller.selectedCategoryId.value,
      );
      return GestureDetector(
        onTap: () => openCategoryPopup(),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  selected?.name ?? "Pilih Kategori",
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              const Icon(Icons.arrow_drop_down, color: Colors.grey),
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
        height: 400,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          children: [
            const Text(
              "Pilih / Tambah Kategori",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Obx(
                () => ListView(
                  children: controller.categoryList.map((c) {
                    return ListTile(
                      title: Text(c.name),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _confirmDeleteCategory(c.id),
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
            TextField(
              onChanged: (_) => controller.isDirty.value = true,
              controller: newCategoryC,
              decoration: const InputDecoration(hintText: "Nama kategori baru"),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
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
                child: const Text("Tambah"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteCategory(String id) {
    Get.defaultDialog(
      title: "Hapus Kategori",
      middleText: "Yakin mau hapus kategori ini?",
      textConfirm: "Hapus",
      textCancel: "Batal",
      confirmTextColor: Colors.white,
      buttonColor: Colors.red,
      onConfirm: () async {
        Get.back();
        await controller.deleteCategory(id);
      },
    );
  }

  // ================= SHARED: VARIANT FORM =================
  Widget variantForm({bool isEditMode = false}) {
    return _card(
      "Tambah Variant Baru",
      Column(
        children: [
          _input(variantC.variantNameC, "Nama Variant"),
          _input(variantC.variantStockC, "Stock", isNumberOnly: true),
          _input(variantC.variantBarcodeC, "Barcode (opsional)"),
          const SizedBox(height: 12),
          unitDropdown(),
          const SizedBox(height: 12),
          priceMatrix(),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () =>
                  variantC.addVariantFromForm(isEditMode: isEditMode),
              child: const Text("Tambah Variant"),
            ),
          ),
        ],
      ),
    );
  }

  // ================= SHARED: UNIT DROPDOWN =================
  Widget unitDropdown() {
    return GestureDetector(
      onTap: () => openUnitPopup(),
      child: Obx(() {
        final selected = variantC.unitList.firstWhereOrNull(
          (u) => u.id == variantC.selectedUnitId.value,
        );
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  selected != null
                      ? "${selected.name} (${selected.symbol})"
                      : "Pilih Unit",
                ),
              ),
              const Icon(Icons.arrow_drop_down, color: Colors.grey),
            ],
          ),
        );
      }),
    );
  }

  void openUnitPopup() {
    final nameC = TextEditingController();
    final symbolC = TextEditingController();
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(16),
        height: 420,
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
            Expanded(
              child: Obx(
                () => ListView(
                  children: variantC.unitList.map((u) {
                    return ListTile(
                      title: Text("${u.name} (${u.symbol})"),
                      onTap: () {
                        variantC.selectedUnitId.value = u.id;
                        Get.back();
                      },
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _confirmDeleteUnit(u.id),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const Divider(),
            TextField(
              onChanged: (_) => controller.isDirty.value = true,
              controller: nameC,
              decoration: const InputDecoration(hintText: "Nama Unit"),
            ),
            const SizedBox(height: 6),
            TextField(
              onChanged: (_) => controller.isDirty.value = true,
              controller: symbolC,
              decoration: const InputDecoration(
                hintText: "Symbol (pcs, box, dll)",
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  if (nameC.text.isEmpty || symbolC.text.isEmpty) return;
                  final newId = await variantC.createUnit(
                    nameC.text.trim(),
                    symbolC.text.trim(),
                  );
                  if (newId != null) {
                    variantC.selectedUnitId.value = newId;
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

  void _confirmDeleteUnit(String id) {
    Get.defaultDialog(
      title: "Hapus Unit",
      middleText: "Yakin mau hapus unit ini?",
      textConfirm: "Hapus",
      textCancel: "Batal",
      confirmTextColor: Colors.white,
      buttonColor: Colors.red,
      onConfirm: () async {
        Get.back();
        await variantC.deleteUnit(id);
      },
    );
  }

  // ================= SHARED: PRICE MATRIX =================
  Widget priceMatrix() {
    return Obx(() {
      if (variantC.priceListMaster.isEmpty) {
        return const Text(
          "Belum ada price list",
          style: TextStyle(color: Colors.grey),
        );
      }
      return Column(
        children: variantC.priceListMaster.map((p) {
          return Obx(() {
            final enabled =
                variantC.formPrices[p.id]?['enabled'] as bool? ?? false;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 110,
                    child: Text(p.name, style: const TextStyle(fontSize: 13)),
                  ),
                  Expanded(
                    child: TextField(
                      controller: variantC.priceControllers[p.id],
                      keyboardType: TextInputType.number,
                      enabled: enabled,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        CurrencyInputFormatter(),
                      ],
                      decoration: InputDecoration(
                        hintText: "Harga",
                        prefixText: "Rp ",
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: const OutlineInputBorder(
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (_) => controller.isDirty.value = true,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      enabled ? Icons.check_circle : Icons.add_circle_outline,
                      color: enabled ? Colors.green : Colors.grey,
                    ),
                    onPressed: () {
                      variantC.togglePrice(p.id);
                      controller.isDirty.value = true;
                    },
                  ),
                ],
              ),
            );
          });
        }).toList(),
      );
    });
  }

  // ================= PRIVATE HELPERS =================
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

  Widget _input(
    TextEditingController c,
    String hint, {
    bool isNumberOnly = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: c,
        onChanged: (_) => controller.isDirty.value = true,
        keyboardType: isNumberOnly ? TextInputType.number : TextInputType.text,
        inputFormatters: isNumberOnly
            ? [FilteringTextInputFormatter.digitsOnly]
            : null,
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: Colors.grey.shade100,
          border: const OutlineInputBorder(borderSide: BorderSide.none),
        ),
      ),
    );
  }
}
