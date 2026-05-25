import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:senkukoadmin/constant/app_toast.dart';
import 'package:senkukoadmin/constant/api_helper.dart';
import 'package:senkukoadmin/features/products/controllers/category_controller.dart';
import 'package:senkukoadmin/features/products/controllers/price_controller.dart';
import 'package:senkukoadmin/features/products/controllers/product_image_controller.dart';
import 'package:senkukoadmin/features/products/controllers/product_variant_controller.dart';
import 'package:senkukoadmin/features/products/controllers/unit_controller.dart';
import 'package:senkukoadmin/features/products/models/product_image_model.dart';
import 'package:senkukoadmin/features/products/models/product_model.dart';
import 'package:senkukoadmin/features/products/models/product_variant_model.dart';
import 'package:senkukoadmin/features/products/product_service.dart';

class ProductController extends GetxController {
  ProductImageController get imageC => Get.find<ProductImageController>();
  ProductVariantController get variantC => Get.find<ProductVariantController>();
  CategoryController get categoryC => Get.find<CategoryController>();
  PriceController get priceC => Get.find<PriceController>();
  UnitController get unitC => Get.find<UnitController>();

  // ===================== STATE =====================
  final isLoading = false.obs;
  final isLoadingDetail = false.obs;
  final isSubmitting = false.obs;
  final editingProductId = ''.obs;
  final isDirty = false.obs;

  // ===================== DATA =====================
  final productList = <ProductData>[].obs;
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
            selectedTab.value == 'Semua' ||
            p.categoryName == selectedTab.value;
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

  List<String> get tabs => [
    'Semua',
    ...categoryC.categoryList.map((c) => c.name),
  ];

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
    _categoryWorker?.dispose();
    _pendingImagesWorker?.dispose();
    _pendingEditImagesWorker?.dispose();
    _variantsTempWorker?.dispose();
    for (final c in [nameC, skuC, descC, barcodeC]) {
      c.removeListener(checkDirty);
      c.dispose();
    }
    super.onClose();
  }

  // ===================== INIT =====================
  Future<void> loadInitialData() async {
    if (isLoading.value) return;
    isLoading.value = true;
    try {
      // Semua fetch jalan parallel — categories, units, price lists
      // fetchProducts sudah handle image fetch di background sendiri
      await Future.wait([
        fetchProducts(),
        categoryC.fetchCategories(),
        priceC.fetchPrices(),
        priceC.fetchPriceLists(),
        unitC.fetchUnits(),
        variantC.fetchAllVariants(),
      ]);
    } catch (e) {
      AppToast.show('Gagal memuat data awal');
    } finally {
      isLoading.value = false;
    }
  }

  // ===================== FETCH =====================
  Future<void> fetchProducts() async {
    try {
      final res = await ProductService.getProducts();
      if (res.statusCode == 200) {
        final newProducts = productModelFromJson(res.body).data;
        productList.assignAll(newProducts);
        _applyFilter();

        // Image fetch di background — tidak block UI
        // List produk sudah tampil, gambar menyusul
        _fetchAllImagesBackground(newProducts);
      } else if (ApiHelper.isNetworkError(res)) {
        AppToast.show(ApiHelper.parseError(res.body));
      } else {
        AppToast.show('Gagal memuat daftar produk');
      }
    } catch (e) {
      AppToast.show('Terjadi kesalahan saat memuat produk');
    }
  }

  // Background fetch — fire and forget, tidak di-await
  void _fetchAllImagesBackground(List<ProductData> products) {
    Future.microtask(() async {
      final cache = <String, List<ProductImageData>>{};
      await _fetchImagesInBatches(products, cache);
      imageC.replaceAllCache(cache);
    });
  }

  Future<void> _fetchImagesInBatches(
    List<ProductData> products,
    Map<String, List<ProductImageData>> cache, {
    int batchSize = 5,
  }) async {
    for (var i = 0; i < products.length; i += batchSize) {
      final batch = products.skip(i).take(batchSize).toList();
      await Future.wait(
        batch.map((p) => imageC.fetchProductImagesInto(p.id, cache)),
      );
    }
  }

  // ===================== FORM RESET =====================
  void resetForAddProduct() {
    isDirty.value = false;
    editingProductId.value = '';
    selectedProduct.value = null;

    _clearProductForm();

    _snapName = '';
    _snapSku = '';
    _snapDesc = '';
    _snapBarcode = '';
    _snapCategoryId = '';

    variantC.clearVariantForm();
    variantC.variantsTemp.clear();
    variantC.editVariantsTemp.clear();
    variantC.productVariants.clear();
    imageC.pendingImages.clear();

    _listenFormChanges();
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
      AppToast.show('Gagal memuat detail produk');
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
    variantC.variantsTemp.clear();
    imageC.pendingEditImages.clear();

    editingProductId.value = productId;
    isLoadingDetail.value = true;

    try {
      await Future.wait([
        if (categoryC.categoryList.isEmpty) categoryC.fetchCategories(),
        if (priceC.priceListMaster.isEmpty) priceC.fetchPriceLists(),
        if (unitC.unitList.isEmpty) unitC.fetchUnits(),
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

      _takeSnapshot();
      isDirty.value = false;
      _listenFormChanges();
    } catch (e) {
      AppToast.show('Gagal memuat data produk');
    } finally {
      isLoadingDetail.value = false;
    }
  }

  // ===================== CREATE PRODUCT =====================
  Future<bool> createFullProduct() async {
    if (nameC.text.trim().isEmpty || skuC.text.trim().isEmpty) {
      AppToast.show('Nama dan SKU Code harus diisi');
      return false;
    }
    if (variantC.variantsTemp.isEmpty) {
      AppToast.show('Minimal tambahkan 1 variant');
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
        AppToast.show(ApiHelper.parseError(productRes.body));
        return false;
      }

      if (productRes.statusCode != 201) {
        AppToast.show('Gagal membuat produk');
        return false;
      }

      final newProductId =
          json.decode(productRes.body)['data']['id']?.toString() ?? '';

      // Buat semua variant — biarkan partial failure tidak block semua
      for (var v in variantC.variantsTemp) {
        try {
          await variantC.createVariantWithPrices(
            productId: newProductId,
            variantData: v,
          );
        } catch (_) {}
      }

      await imageC.uploadPendingImages(newProductId);

      // Refresh data global setelah create
      await Future.wait([
        variantC.fetchAllVariants(),
        priceC.fetchPrices(),
        fetchProducts(),
      ]);

      resetForAddProduct();
      AppToast.show('Produk berhasil ditambahkan');
      return true;
    } catch (e) {
      AppToast.show('Terjadi kesalahan saat menyimpan');
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  // ===================== UPDATE PRODUCT =====================
  Future<void> updateFullProduct() async {
    if (editingProductId.value.isEmpty) {
      AppToast.show('Product ID tidak ditemukan');
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
        AppToast.show(ApiHelper.parseError(productRes.body));
        return;
      }

      if (productRes.statusCode < 200 || productRes.statusCode >= 300) {
        AppToast.show('Gagal update informasi produk');
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

      // Refresh data global setelah update
      await Future.wait([
        variantC.fetchAllVariants(),
        priceC.fetchPrices(),
        fetchProducts(),
      ]);

      // Reset _dirty flag di semua edit variants
      for (var i = 0; i < variantC.editVariantsTemp.length; i++) {
        variantC.editVariantsTemp[i] = {
          ...variantC.editVariantsTemp[i],
          '_dirty': false,
        };
      }
      variantC.editVariantsTemp.refresh();

      AppToast.show('Produk berhasil diupdate');
    } catch (e) {
      AppToast.show('Terjadi kesalahan saat menyimpan perubahan');
    } finally {
      isSubmitting.value = false;
    }
  }

  // ===================== DIRTY TRACKING =====================
  String _snapName = '';
  String _snapSku = '';
  String _snapDesc = '';
  String _snapBarcode = '';
  String _snapCategoryId = '';

  Worker? _categoryWorker;
  Worker? _pendingImagesWorker;
  Worker? _pendingEditImagesWorker;
  Worker? _variantsTempWorker;

  void _takeSnapshot() {
    _snapName = nameC.text;
    _snapSku = skuC.text;
    _snapDesc = descC.text;
    _snapBarcode = barcodeC.text;
    _snapCategoryId = selectedCategoryId.value;
  }

  void checkDirty() {
    isDirty.value =
        nameC.text != _snapName ||
        skuC.text != _snapSku ||
        descC.text != _snapDesc ||
        barcodeC.text != _snapBarcode ||
        selectedCategoryId.value != _snapCategoryId ||
        imageC.pendingEditImages.isNotEmpty ||
        imageC.pendingImages.isNotEmpty ||
        variantC.variantsTemp.isNotEmpty ||
        variantC.editVariantsTemp.any(
          (v) => v['id'] == '' || v['_dirty'] == true,
        );
  }

  void _listenFormChanges() {
    for (final c in [nameC, skuC, descC, barcodeC]) {
      c.removeListener(checkDirty);
      c.addListener(checkDirty);
    }

    _categoryWorker?.dispose();
    _pendingImagesWorker?.dispose();
    _pendingEditImagesWorker?.dispose();
    _variantsTempWorker?.dispose();

    _categoryWorker = ever(selectedCategoryId, (_) => checkDirty());
    _pendingImagesWorker = ever(imageC.pendingImages, (_) => checkDirty());
    _pendingEditImagesWorker = ever(
      imageC.pendingEditImages,
      (_) => checkDirty(),
    );
    _variantsTempWorker = ever(variantC.variantsTemp, (_) => checkDirty());
  }
}