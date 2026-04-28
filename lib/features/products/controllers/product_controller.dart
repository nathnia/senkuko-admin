import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:senkukoadmin/features/products/controllers/product_image_controller.dart';
import 'package:senkukoadmin/features/products/controllers/product_variant_controller.dart';
import 'package:senkukoadmin/features/products/models/category_model.dart';
import 'package:senkukoadmin/features/products/models/product_model.dart';
import 'package:senkukoadmin/features/products/models/product_variant_model.dart';
import 'package:senkukoadmin/features/products/product_service.dart';

class ProductController extends GetxController {
  ProductImageController get imageC => Get.find<ProductImageController>();
  ProductVariantController get variantC => Get.find<ProductVariantController>();

  // ===================== STATE =====================
  final isLoading = false.obs;
  final isLoadingDetail = false.obs;
  final isSubmitting = false.obs;
  final isEditMode = false.obs;
  final editingProductId = ''.obs;
  final isDirty = false.obs;

  // ===================== DATA =====================
  final productList = <ProductData>[].obs;
  final categoryList = <CategoryData>[].obs;

  final selectedProduct = Rxn<ProductData>();

  // ===================== PRODUCT PAGE STATE =====================

  // Method untuk update search
  void updateSearch(String value) {
    searchText.value = value;
  }

  // Method untuk ganti tab
  void changeTab(String tab) {
    selectedTab.value = tab;
  }

  final searchText = ''.obs;
  final selectedTab = 'Semua'.obs;
  final List<String> tabs = ['Semua', 'Aktif', 'Non-Aktif'];

  List<ProductData> get filteredProducts {
    return productList.where((p) {
      final matchSearch = p.name.toLowerCase().contains(
        searchText.value.toLowerCase(),
      );
      final matchTab =
          selectedTab.value == 'Semua' ||
          (selectedTab.value == 'Aktif' && p.isActive == 1) ||
          (selectedTab.value == 'Non-Aktif' && p.isActive == 0);
      return matchSearch && matchTab;
    }).toList();
  }

  // ===================== PRODUCT FORM =====================
  final nameC = TextEditingController();
  final skuC = TextEditingController();
  final descC = TextEditingController();
  final barcodeC = TextEditingController();
  final selectedCategoryId = ''.obs;

  // ===================== LIFECYCLE =====================
  @override
  void onInit() {
    super.onInit();
    loadInitialData();
  }

  @override
  void onClose() {
    nameC.dispose();
    skuC.dispose();
    descC.dispose();
    barcodeC.dispose();
    super.onClose();
  }

  // ===================== INIT =====================
  Future<void> loadInitialData() async {
    isLoading.value = true;
    try {
      await Future.wait([fetchProducts(), fetchCategories()]);
    } catch (e) {
      Get.snackbar('Error', 'Gagal memuat data awal');
    } finally {
      isLoading.value = false;
    }
  }

  // ===================== FETCH =====================
  Future<void> fetchProducts() async {
    final res = await ProductService.getProducts();
    if (res.statusCode == 200) {
      productList.assignAll(productModelFromJson(res.body).data);

      await Future.wait(
        productList.map((p) => imageC.fetchProductImages(p.id)),
      );
    }
  }

  Future<void> fetchCategories() async {
    final res = await ProductService.getCategories();
    if (res.statusCode == 200) {
      final jsonData = json.decode(res.body);
      categoryList.assignAll(
        (jsonData['data'] as List? ?? [])
            .map((e) => CategoryData.fromJson(e))
            .toList(),
      );
    }
  }

  // ===================== FORM RESET =====================
  void resetForAddProduct() {
    isDirty.value = false;
    isEditMode.value = false;
    editingProductId.value = '';
    selectedProduct.value = null;

    _clearProductForm();

    variantC.clearVariantForm();

    variantC.variantsTemp.clear();
    variantC.editVariantsTemp.clear();
    variantC.productVariants.clear();
    imageC.pendingImages.clear();
  }

  void _clearProductForm() {
    nameC.clear();
    skuC.clear();
    descC.clear();
    barcodeC.clear();
    selectedCategoryId.value = '';
  }

  // ===================== PRODUCT DETAIL =====================
  Future<void> loadProductDetail(String productId) async {
    isLoadingDetail.value = true;
    selectedProduct.value = null;
    variantC.productVariants.clear();

    try {
      final results = await Future.wait([
        ProductService.getVariants(productId),
        ProductService.getProductById(productId),
      ]);

      final variantRes = results[0];
      final productRes = results[1];

      if (variantRes.statusCode == 200) {
        final jsonData = json.decode(variantRes.body);
        final List raw = jsonData['data']?['variants'] ?? [];
        variantC.productVariants.assignAll(
          raw.map((e) => VariantData.fromJson(e)).toList(),
        );
      }

      if (productRes.statusCode == 200) {
        final jsonData = json.decode(productRes.body);
        if (jsonData['data'] != null) {
          selectedProduct.value = ProductData.fromJson(jsonData['data']);
        }
      }
    } catch (e) {
      Get.snackbar('Error', 'Gagal memuat detail produk');
    } finally {
      isLoadingDetail.value = false;
    }
  }


// ===================== TOGGLE ACTIVE =====================
Future<void> toggleProductActive(ProductData product) async {
  final isActive = product.isActive == 1;
  final newStatus = !isActive;

  try {
    final res = await ProductService.updateProduct(
      id: product.id,
      name: product.name,
      skuCode: product.skuCode,
      description: product.description ?? '',
      barcode: product.barcode ?? '',
      categoryId: product.categoryId,
      isActive: newStatus,
    );

    if (res.statusCode >= 200 && res.statusCode < 300) {
      await fetchProducts();
      Get.snackbar(
        'Berhasil',
        '"${product.name}" ${newStatus ? 'diaktifkan' : 'dinonaktifkan'}',
        backgroundColor: newStatus ? Colors.green : Colors.orange,
        colorText: Colors.white,
      );
    } else {
      Get.snackbar('Gagal', 'Gagal mengubah status produk');
    }
  } catch (e) {
    Get.snackbar('Error', 'Terjadi kesalahan');
  }
}
  // ===================== LOAD EDIT DATA =====================
  Future<void> loadEditData(String productId) async {
    // Reset dulu
    isDirty.value = false;
    selectedProduct.value = null;
    nameC.clear();
    skuC.clear();
    descC.clear();
    barcodeC.clear();
    selectedCategoryId.value = '';
    variantC.editVariantsTemp.clear();

    isEditMode.value = true;
    editingProductId.value = productId;
    isLoadingDetail.value = true;

    try {
      // ← Semua fetch jalan BERSAMAAN
      debugPrint('⏱ loadEditData start');
      await Future.wait([
        if (variantC.priceListMaster.isEmpty) variantC.fetchPriceLists(),
        if (variantC.unitList.isEmpty) variantC.fetchUnits(),
        loadProductDetail(productId),
        imageC.fetchProductImages(productId),
      ]);
      debugPrint('⏱ Future.wait done');
      // ← Ini tetap setelah loadProductDetail selesai
      await variantC.loadEditVariants();
      debugPrint('⏱ loadEditVariants done');
      final p = selectedProduct.value;
      if (p != null) {
        nameC.text = p.name;
        skuC.text = p.skuCode;
        descC.text = p.description ?? '';
        barcodeC.text = p.barcode ?? '';
        selectedCategoryId.value = p.categoryId ?? '';
      }

      variantC.initPriceControllers();
    } catch (e) {
      Get.snackbar('Error', 'Gagal memuat data produk');
    } finally {
      isLoadingDetail.value = false;
    }
  }

  // ===================== CREATE PRODUCT =====================
  Future<bool> createFullProduct() async {
    if (nameC.text.trim().isEmpty || skuC.text.trim().isEmpty) {
      Get.snackbar('Validasi', 'Nama dan SKU Code harus diisi');
      return false;
    }
    if (variantC.variantsTemp.isEmpty) {
      Get.snackbar('Validasi', 'Minimal tambahkan 1 variant');
      return false;
    }

    isSubmitting.value = true;
    try {
      final productRes = await ProductService.createProduct(
        name: nameC.text.trim(),
        skuCode: skuC.text.trim(),
        description: descC.text.trim(),
        barcode: barcodeC.text.trim(),
        categoryId: selectedCategoryId.value.isEmpty
            ? null
            : selectedCategoryId.value,
      );

      if (productRes.statusCode != 201) {
        Get.snackbar('Gagal', 'Gagal membuat produk');
        return false;
      }

      final newProductId =
          json.decode(productRes.body)['data']['id']?.toString() ?? '';

      for (var v in variantC.variantsTemp) {
        await variantC.createVariantWithPrices(
          productId: newProductId,
          variantData: v,
        );
      }

      // Upload semua gambar yang dipending
      await imageC.uploadPendingImages(newProductId);

      await Future.wait([fetchProducts(), variantC.fetchPrices()]);
      resetForAddProduct();

      Get.snackbar(
        'Sukses',
        'Produk berhasil ditambahkan',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      return true;
    } catch (e) {
      Get.snackbar('Error', 'Terjadi kesalahan saat menyimpan');
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  // ===================== UPDATE PRODUCT =====================
  Future<void> updateFullProduct() async {
    if (editingProductId.value.isEmpty) {
      Get.snackbar('Error', 'Product ID tidak ditemukan');
      return;
    }

    isSubmitting.value = true;

    try {
      // 1. Update produk utama
      final productRes = await ProductService.updateProduct(
        id: editingProductId.value,
        name: nameC.text.trim(),
        skuCode: skuC.text.trim(),
        description: descC.text.trim(),
        barcode: barcodeC.text.trim(),
        categoryId: selectedCategoryId.value.isEmpty
            ? null
            : selectedCategoryId.value,
      );

      if (productRes.statusCode < 200 || productRes.statusCode >= 300) {
        Get.snackbar('Error', 'Gagal update informasi produk');
        return;
      }

      // 2. Update setiap variant
      for (var v in variantC.editVariantsTemp) {
        final variantId = v['id']?.toString() ?? '';

        if (variantId.isEmpty) {
          // Variant baru ditambahkan saat edit
          await variantC.createVariantWithPrices(
            productId: editingProductId.value,
            variantData: v,
          );
          continue;
        }

        await variantC.updateExistingVariant(v);
      }

      Get.snackbar(
        'Sukses',
        'Produk berhasil diupdate',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      await Future.wait([fetchProducts(), variantC.fetchPrices()]);
      Get.back();
    } catch (e) {
      Get.snackbar('Error', 'Terjadi kesalahan saat menyimpan perubahan');
    } finally {
      isSubmitting.value = false;
    }
  }

  // ===================== DELETE PRODUCT =====================
  Future<void> deleteProduct(String productId, String productName) async {
    if (productId.isEmpty) return;

    final confirmed = await _showConfirmDialog(
      title: 'Hapus Produk',
      content:
          'Yakin ingin menghapus "$productName"?\n\nSemua variant dan harga akan ikut terhapus.',
    );
    if (!confirmed) return;

    isSubmitting.value = true;
    try {
      final res = await ProductService.deleteProduct(productId);

      if (res.statusCode == 200 || res.statusCode == 204) {
        Get.snackbar(
          'Sukses',
          'Produk "$productName" berhasil dihapus',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        await fetchProducts();
        Get.back();
      } else {
        final msg = _parseErrorMessage(res.body);
        Get.snackbar('Gagal', msg);
      }
    } catch (e) {
      Get.snackbar('Error', 'Terjadi kesalahan saat menghapus produk');
    } finally {
      isSubmitting.value = false;
    }
  }

  // ===================== CATEGORY HELPERS =====================
  Future<String?> createCategory(String name) async {
    try {
      final res = await ProductService.createCategory(name);
      if (res.statusCode == 201) {
        return json.decode(res.body)['data']['id'];
      }
    } catch (e) {
      Get.snackbar('Error', 'Gagal tambah category');
    }
    return null;
  }

  Future<void> deleteCategory(String id) async {
    try {
      final res = await ProductService.deleteCategory(id);
      if (res.statusCode == 200) {
        categoryList.removeWhere((c) => c.id == id);
        if (selectedCategoryId.value == id) selectedCategoryId.value = '';
        Get.snackbar('Sukses', 'Category berhasil dihapus');
      } else {
        Get.snackbar('Gagal', _parseErrorMessage(res.body));
      }
    } catch (e) {
      Get.snackbar('Error', 'Terjadi kesalahan');
    }
  }

  // Tambah di product_controller.dart
  String getMainPriceForProduct(ProductData product) {
    final prices = variantC.priceList;
    if (prices.isEmpty) return '0';
    final candidate = prices.firstWhereOrNull((price) {
      final variantName = price.productVariantName.toLowerCase();
      final productName = product.name.toLowerCase();
      return variantName.contains(productName) ||
          productName.contains(variantName.split(' ').first);
    });
    return candidate?.price ?? '0';
  }

  int getAdditionalPriceCountForProduct(ProductData product) {
    final prices = variantC.priceList;
    if (prices.isEmpty) return 0;
    if (getMainPriceForProduct(product) == '0') return 0;
    final count = prices.where((price) {
      final variantName = price.productVariantName.toLowerCase();
      final productName = product.name.toLowerCase();
      return variantName.contains(productName) ||
          productName.contains(variantName.split(' ').first);
    }).length;
    return count > 1 ? count - 1 : 0;
  }

  // ===================== PRIVATE UTILITIES =====================
  Future<bool> _showConfirmDialog({
    required String title,
    required String content,
  }) async {
    final confirmed = false.obs;
    await Get.dialog(
      AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              confirmed.value = true;
              Get.back();
            },
            child: const Text(
              'Ya, Hapus',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      barrierDismissible: false,
    );
    return confirmed.value;
  }

  String _parseErrorMessage(String body) {
    try {
      return json.decode(body)['message'] ?? 'Terjadi kesalahan';
    } catch (_) {
      return 'Terjadi kesalahan';
    }
  }
}
