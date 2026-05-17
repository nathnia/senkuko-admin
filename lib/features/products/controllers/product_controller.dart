import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:senkukoadmin/constant/app_toast.dart';
import 'package:senkukoadmin/constant/api_helper.dart';
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
  final editingProductId = ''.obs;
  final isDirty = false.obs;

  // ===================== DATA =====================
  final productList = <ProductData>[].obs;
  final categoryList = <CategoryData>[].obs;
  final selectedProduct = Rxn<ProductData>();

  // ===================== PRODUCT PAGE STATE =====================
  final searchText = ''.obs;
  final selectedTab = 'Semua'.obs;

  final filteredProducts = <ProductData>[].obs;

  void _applyFilter() {
    filteredProducts.assignAll(
      productList.where((p) {
        final matchSearch = p.name.toLowerCase().contains(
          searchText.value.toLowerCase(),
        );
        final matchTab =
            selectedTab.value == 'Semua' || p.categoryName == selectedTab.value;
        return matchSearch && matchTab;
      }).toList(),
    );
  }

  void updateSearch(String value) {
    searchText.value = value;
    _applyFilter();
  }

  void changeTab(String tab) {
    selectedTab.value = tab;
    _applyFilter();
  }

  void resetPageState() {
    searchText.value = '';
    selectedTab.value = 'Semua';
    _applyFilter();
  }

  List<String> get tabs => ['Semua', ...categoryList.map((c) => c.name)];

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
      AppToast.error('Gagal memuat data awal');
    } finally {
      isLoading.value = false;
    }
  }

  // ===================== FETCH =====================
  Future<void> fetchProducts() async {
    isLoading.value = true; // ← Tambahkan ini

    try {
      final res = await ProductService.getProducts();

      if (res.statusCode == 200) {
        final newProducts = productModelFromJson(res.body).data;

        productList.assignAll(newProducts);

        // Fetch images untuk produk yang belum ada gambarnya
        final needFetch = productList
            .where((p) => imageC.getImagesForProduct(p.id).isEmpty)
            .toList();

        if (needFetch.isNotEmpty) {
          await Future.wait(
            needFetch.map((p) => imageC.fetchProductImages(p.id)),
          );
        }

        _applyFilter();
      } else if (ApiHelper.isNetworkError(res)) {
        AppToast.error(ApiHelper.parseError(res.body));
      } else {
        AppToast.error('Gagal memuat daftar produk');
      }
    } catch (e) {
      AppToast.error('Terjadi kesalahan saat memuat produk');
    } finally {
      isLoading.value = false;
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
      AppToast.error('Gagal memuat detail produk');
    } finally {
      isLoadingDetail.value = false;
    }
  }

  // ===================== LOAD EDIT DATA =====================
  Future<void> loadEditData(String productId) async {
    isDirty.value = false;
    selectedProduct.value = null;
    nameC.clear();
    skuC.clear();
    descC.clear();
    barcodeC.clear();
    selectedCategoryId.value = '';
    variantC.editVariantsTemp.clear();
    imageC.pendingEditImages.clear();

    editingProductId.value = productId;
    isLoadingDetail.value = true;

    try {
      await Future.wait([
        if (variantC.priceListMaster.isEmpty) variantC.fetchPriceLists(),
        if (variantC.unitList.isEmpty) variantC.fetchUnits(),
        loadProductDetail(productId),
        imageC.fetchProductImages(productId),
      ]);

      await variantC.loadEditVariants();

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
      AppToast.error('Gagal memuat data produk');
    } finally {
      isLoadingDetail.value = false;
    }
  }

  // ===================== CREATE PRODUCT =====================
  Future<bool> createFullProduct() async {
    if (nameC.text.trim().isEmpty || skuC.text.trim().isEmpty) {
      AppToast.warning('Nama dan SKU Code harus diisi');
      return false;
    }
    if (variantC.variantsTemp.isEmpty) {
      AppToast.warning('Minimal tambahkan 1 variant');
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

      if (ApiHelper.isNetworkError(productRes)) {
        AppToast.error(ApiHelper.parseError(productRes.body));
        return false;
      }

      if (productRes.statusCode != 201) {
        AppToast.error('Gagal membuat produk');
        return false;
      }

      final newProductId =
          json.decode(productRes.body)['data']['id']?.toString() ?? '';

      for (var v in variantC.variantsTemp) {
        try {
          await variantC.createVariantWithPrices(
            productId: newProductId,
            variantData: v,
          );
        } catch (e) {
          debugPrint('Variant create failed: $e');
        }
      }

      await imageC.uploadPendingImages(newProductId);

      await variantC.fetchAllVariants();
      await variantC.fetchPrices();
      await fetchProducts();

      resetForAddProduct();
      AppToast.success('Produk berhasil ditambahkan');
      return true;
    } catch (e) {
      AppToast.error('Terjadi kesalahan saat menyimpan');
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  // ===================== UPDATE PRODUCT =====================
  Future<void> updateFullProduct() async {
    if (editingProductId.value.isEmpty) {
      AppToast.error('Product ID tidak ditemukan');
      return;
    }

    isSubmitting.value = true;

    try {
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

      if (ApiHelper.isNetworkError(productRes)) {
        AppToast.error(ApiHelper.parseError(productRes.body));
        return;
      }

      if (productRes.statusCode < 200 || productRes.statusCode >= 300) {
        AppToast.error('Gagal update informasi produk');
        return;
      }

      for (var v in variantC.editVariantsTemp) {
        final variantId = v['id']?.toString() ?? '';

        if (variantId.isEmpty) {
          await variantC.createVariantWithPrices(
            productId: editingProductId.value,
            variantData: v,
          );
          continue;
        }

        await variantC.updateExistingVariant(v);
      }

      await imageC.uploadPendingEditImages(editingProductId.value);
      await imageC.fetchProductImages(editingProductId.value);

      await variantC.fetchAllVariants();
      await variantC.fetchPrices();
      await fetchProducts();
    } catch (e) {
      AppToast.error('Terjadi kesalahan saat menyimpan perubahan');
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
      AppToast.error('Gagal tambah category');
    }
    return null;
  }

  Future<void> deleteCategory(String id) async {
    try {
      final res = await ProductService.deleteCategory(id);
      if (res.statusCode == 200) {
        categoryList.removeWhere((c) => c.id == id);
        if (selectedCategoryId.value == id) selectedCategoryId.value = '';
        AppToast.success('Category berhasil dihapus');
      } else {
        AppToast.error(ApiHelper.parseError(res.body));
      }
    } catch (e) {
      AppToast.error('Terjadi kesalahan');
    }
  }
}
