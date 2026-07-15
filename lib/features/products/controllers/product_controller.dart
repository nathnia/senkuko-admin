import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:senkukoadmin/constant/app_toast.dart';
import 'package:senkukoadmin/constant/api_helper.dart';
import 'package:senkukoadmin/constant/currency_formatter.dart';
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

  // ADDED: O(1) dirty variant flag — updated only when variants list changes,
  // not recomputed on every keypress via .any()
  final hasDirtyVariants = false.obs;

  // ===================== DATA =====================
  final productList = <ProductData>[].obs;
  final selectedProduct = Rxn<ProductData>();

  // ===================== PRODUCT PAGE STATE =====================
  final searchText = ''.obs;
  final selectedTab = 'Semua'.obs;
  final selectedSort = ''.obs;

  // ADDED: stock status filters for inventory workflows
  final showLowStockOnly = false.obs;
  final showOutOfStockOnly = false.obs;
  // Threshold configurable per business — default 5 units
  final lowStockThreshold = 5.obs;

  // PRICE FILTER
  final minPrice = RxnDouble();
  final maxPrice = RxnDouble();
  final minPriceC = TextEditingController();
  final maxPriceC = TextEditingController();

  // ADDED: debounce timer for search — prevents filtering on every keypress
  Timer? _searchDebounce;

  // ===================== SORT =====================
  void sortNewest() => selectedSort.value = 'newest';
  void sortOldest() => selectedSort.value = 'oldest';
  void sortPriceLowToHigh() => selectedSort.value = 'price_asc';
  void sortPriceHighToLow() => selectedSort.value = 'price_desc';
  void sortAZ() => selectedSort.value = 'az';
  void sortLowStock() => selectedSort.value = 'low_stock';

  // ADDED: human-readable sort label for active filter chip display
  String get sortLabel {
    switch (selectedSort.value) {
      case 'newest':
        return 'Terbaru';
      case 'oldest':
        return 'Terlama';
      case 'price_asc':
        return 'Harga Termurah';
      case 'price_desc':
        return 'Harga Termahal';
      case 'az':
        return 'A–Z';
      case 'low_stock':
        return 'Stok Menipis';
      default:
        return '';
    }
  }

  // ADDED: human-readable price range label for active filter chip
  String get priceRangeLabel {
    final min = minPrice.value;
    final max = maxPrice.value;
    if (min != null && max != null) {
      return '${CurrencyFormatter.format(min)}–${CurrencyFormatter.format(max)}';
    }
    if (min != null) return '≥ ${CurrencyFormatter.format(min)}';
    if (max != null) return '≤ ${CurrencyFormatter.format(max)}';
    return '';
  }

  // ===================== PRICE FILTER =====================
  void applyPriceFilter() {
    final min = double.tryParse(
      minPriceC.text
          .replaceAll('.', '')
          .replaceAll(',', '')
          .replaceAll('Rp', '')
          .trim(),
    );
    final max = double.tryParse(
      maxPriceC.text
          .replaceAll('.', '')
          .replaceAll(',', '')
          .replaceAll('Rp', '')
          .trim(),
    );
    minPrice.value = min;
    maxPrice.value = max;
  }

  void setPriceRange({double? min, double? max}) {
    minPrice.value = min;
    maxPrice.value = max;
    minPriceC.text = min != null ? min.toStringAsFixed(0) : '';
    maxPriceC.text = max != null ? max.toStringAsFixed(0) : '';
  }

  void clearPriceRange() {
    minPrice.value = null;
    maxPrice.value = null;
    minPriceC.clear();
    maxPriceC.clear();
  }

  bool get hasActiveFilters =>
      selectedSort.value.isNotEmpty ||
      minPrice.value != null ||
      maxPrice.value != null ||
      showLowStockOnly.value ||
      showOutOfStockOnly.value;

  // ===================== FILTERED + SORTED PRODUCT LIST =====================
  List<ProductData> get getFilteredProducts {
    var products = [...productList];

    // SEARCH
    if (searchText.value.isNotEmpty) {
      final q = searchText.value.toLowerCase();
      products = products
          .where((p) => p.name.toLowerCase().contains(q))
          .toList();
    }

    if (selectedTab.value != 'Semua') {
      products = products.where((p) {
        if (p.categoryName.isEmpty) return false;
        final parentName = categoryC.resolveParentName(p.categoryName);
        return parentName == selectedTab.value;
      }).toList();
    }

    // PRICE FILTER
    if (minPrice.value != null || maxPrice.value != null) {
      products = products.where((product) {
        final price = variantC.getSummaryForProduct(product.id).mainPriceValue;
        final minOk = minPrice.value == null || price >= minPrice.value!;
        final maxOk = maxPrice.value == null || price <= maxPrice.value!;
        return minOk && maxOk;
      }).toList();
    }

    // LOW STOCK FILTER
    if (showLowStockOnly.value) {
      products = products.where((p) {
        final stock = variantC.getSummaryForProduct(p.id).totalStock;
        return stock > 0 && stock <= lowStockThreshold.value;
      }).toList();
    }

    // OUT OF STOCK FILTER
    if (showOutOfStockOnly.value) {
      products = products
          .where((p) => variantC.getSummaryForProduct(p.id).isOutOfStock)
          .toList();
    }

    // SORT
    switch (selectedSort.value) {
      case 'newest':
        products.sort((a, b) {
          final aDate =
              DateTime.tryParse(a.createdAt.toString()) ?? DateTime(2000);
          final bDate =
              DateTime.tryParse(b.createdAt.toString()) ?? DateTime(2000);
          return bDate.compareTo(aDate);
        });
        break;
      case 'oldest':
        products.sort((a, b) {
          final aDate =
              DateTime.tryParse(a.createdAt.toString()) ?? DateTime(2000);
          final bDate =
              DateTime.tryParse(b.createdAt.toString()) ?? DateTime(2000);
          return aDate.compareTo(bDate);
        });
        break;
      case 'az':
        products.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'price_asc':
        products.sort((a, b) {
          final aPrice = variantC.getSummaryForProduct(a.id).mainPriceValue;
          final bPrice = variantC.getSummaryForProduct(b.id).mainPriceValue;
          return aPrice.compareTo(bPrice);
        });
        break;
      case 'price_desc':
        products.sort((a, b) {
          final aPrice = variantC.getSummaryForProduct(a.id).mainPriceValue;
          final bPrice = variantC.getSummaryForProduct(b.id).mainPriceValue;
          return bPrice.compareTo(aPrice);
        });
        break;
      case 'low_stock':
        products.sort((a, b) {
          final aStock = variantC.getSummaryForProduct(a.id).totalStock;
          final bStock = variantC.getSummaryForProduct(b.id).totalStock;
          return aStock.compareTo(bStock);
        });
        break;
    }

    return products;
  }

  // ===================== FILTER ACTIONS =====================
  void updateSearch(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      searchText.value = value;
    });
  }

  void changeTab(String tab) => selectedTab.value = tab;

  void resetPageState() {
    searchText.value = '';
    selectedTab.value = 'Semua';
    selectedSort.value = '';
    showLowStockOnly.value = false; // ADDED
    showOutOfStockOnly.value = false; // ADDED
    clearPriceRange();
    _rebuildTabs();
  }

  // List<String> get tabs => [
  //   'Semua',
  //   ...categoryC.categoryList.map((c) => c.name),
  // ];

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
    _searchDebounce?.cancel(); // ADDED: cancel any pending debounce
    _categoryWorker?.dispose();
    _pendingImagesWorker?.dispose();
    _pendingEditImagesWorker?.dispose();
    _variantsTempWorker?.dispose();
    _editVariantsDirtyWorker?.dispose(); // ADDED
    minPriceC.dispose();
    maxPriceC.dispose();
    for (final c in [nameC, skuC, descC, barcodeC]) {
      c.removeListener(checkDirty);
      c.dispose();
    }
    super.onClose();
  }

  final tabs = <String>['Semua'].obs;

  void _rebuildTabs() {
    tabs.assignAll(['Semua', ...categoryC.parentCategories.map((c) => c.name)]);
  }

  Future<void> loadInitialData() async {
    if (isLoading.value) return;

    // Reset error state before the guard matters
    hasError.value = false;
    errorMessage.value = '';
    isLoading.value = true;

    try {
      await Future.wait([
        fetchProducts(),
        categoryC.fetchCategories(),
        priceC.fetchPrices(),
        priceC.fetchPriceLists(),
        unitC.fetchUnits(),
        variantC.fetchAllVariants(),
      ]);
      _rebuildTabs();
    } catch (e) {
      hasError.value = true;
      errorMessage.value = 'Gagal memuat data. Coba lagi.';
      _rebuildTabs();
    } finally {
      isLoading.value = false;
    }
  }

  final hasError = false.obs;
  final errorMessage = ''.obs;

  Future<void> fetchProducts() async {
    final res = await ProductService.getProducts();
    if (res.statusCode == 200) {
      final newProducts = productModelFromJson(res.body).data;
      productList.assignAll(newProducts);
      _seedImageCacheFromProducts(newProducts);
    } else if (ApiHelper.isNetworkError(res)) {
      throw Exception(ApiHelper.parseError(res.body));
    } else {
      throw Exception('Gagal memuat daftar produk');
    }
  }

  void _seedImageCacheFromProducts(List<ProductData> products) {
    final cache = <String, List<ProductImageData>>{};
    for (final product in products) {
      if (product.images != null && product.images!.isNotEmpty) {
        cache[product.id] = product.images!;
      }
    }
    if (cache.isNotEmpty) {
      imageC.replaceAllCache(cache);
    }
  }

  // ===================== FORM RESET =====================
  void resetForAddProduct() {
    isDirty.value = false;
    hasDirtyVariants.value = false; // ADDED
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
  final hasDetailError = false.obs;
  final detailErrorMessage = ''.obs;

  Future<void> loadProductDetail(String productId) async {
    isLoadingDetail.value = true;
    hasDetailError.value = false;
    detailErrorMessage.value = '';
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
      } else {
        // non-200 juga harus error state, bukan diam
        hasDetailError.value = true;
        detailErrorMessage.value = 'Gagal memuat detail produk. Coba lagi.';
      }
    } catch (e) {
      hasDetailError.value = true;
      detailErrorMessage.value = 'Gagal memuat detail produk. Coba lagi.';
    } finally {
      isLoadingDetail.value = false;
    }
  }

  // ===================== LOAD EDIT DATA =====================
  Future<void> loadEditData(String productId) async {
    if (isLoadingDetail.value) return;

    isDirty.value = false;
    hasDirtyVariants.value = false;
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

      for (var v in variantC.variantsTemp) {
        try {
          await variantC.createVariantWithPrices(
            productId: newProductId,
            variantData: v,
          );
        } catch (_) {}
      }

      await imageC.uploadPendingImages(newProductId);

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
  // CHANGED: return bool — caller only navigates back on real success,
  // instead of always closing the page regardless of outcome.
  Future<bool> updateFullProduct() async {
    if (editingProductId.value.isEmpty) {
      AppToast.show('Product ID tidak ditemukan');
      return false;
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
        return false;
      }

      if (productRes.statusCode < 200 || productRes.statusCode >= 300) {
        AppToast.show('Gagal update informasi produk');
        return false;
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

      await Future.wait([
        variantC.fetchAllVariants(), // already calls invalidateSummaryCache
        priceC.fetchPrices(),
        fetchProducts(),
      ]);

      // Reset _dirty flag
      for (var i = 0; i < variantC.editVariantsTemp.length; i++) {
        variantC.editVariantsTemp[i] = {
          ...variantC.editVariantsTemp[i],
          '_dirty': false,
        };
      }
      variantC.editVariantsTemp.refresh();
      hasDirtyVariants.value = false; // ADDED

      AppToast.show('Produk berhasil diupdate');
      return true;
    } catch (e) {
      AppToast.show('Terjadi kesalahan saat menyimpan perubahan');
      return false;
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
  Worker? _editVariantsDirtyWorker; // ADDED

  void _takeSnapshot() {
    _snapName = nameC.text;
    _snapSku = skuC.text;
    _snapDesc = descC.text;
    _snapBarcode = barcodeC.text;
    _snapCategoryId = selectedCategoryId.value;
  }

  // CHANGED: uses hasDirtyVariants observable instead of .any() on every call
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
        hasDirtyVariants.value; // O(1) read instead of O(N) .any()
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
    _editVariantsDirtyWorker?.dispose();

    _categoryWorker = ever(selectedCategoryId, (_) => checkDirty());
    _pendingImagesWorker = ever(imageC.pendingImages, (_) => checkDirty());
    _pendingEditImagesWorker = ever(
      imageC.pendingEditImages,
      (_) => checkDirty(),
    );
    _variantsTempWorker = ever(variantC.variantsTemp, (_) => checkDirty());

    // ADDED: watch editVariantsTemp changes to update hasDirtyVariants in O(N)
    // only when the list actually changes, not on every keypress
    _editVariantsDirtyWorker = ever(variantC.editVariantsTemp, (list) {
      hasDirtyVariants.value = list.any(
        (v) => v['id'] == '' || v['_dirty'] == true,
      );
      checkDirty();
    });
  }
}