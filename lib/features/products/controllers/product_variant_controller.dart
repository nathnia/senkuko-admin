import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:senkukoadmin/constant/app_dialog.dart';
import 'package:senkukoadmin/constant/app_toast.dart';
import 'package:senkukoadmin/constant/cache_service.dart';
import 'package:senkukoadmin/features/products/controllers/price_controller.dart';
import 'package:senkukoadmin/features/products/controllers/product_controller.dart';
import 'package:senkukoadmin/features/products/controllers/unit_controller.dart';
import 'package:senkukoadmin/features/products/models/product_variant_model.dart';
import 'package:senkukoadmin/features/products/models/product_price_model.dart';
import 'package:senkukoadmin/features/products/product_service.dart';

// ── Product summary — dipakai ProductCard ────────────────────────────────────
class ProductSummary {
  final int totalStock;
  final bool isOutOfStock;
  final double mainPriceValue;
  final int additionalPriceCount;
  final int variantCount;
  final int crisisStockThreshold;

  const ProductSummary({
    required this.totalStock,
    required this.isOutOfStock,
    required this.mainPriceValue,
    required this.additionalPriceCount,
    required this.variantCount,
    required this.crisisStockThreshold,
  });
}

double parseIdPrice(String raw) {
  return double.tryParse(raw.replaceAll('Rp', '').replaceAll(' ', '').trim()) ??
      0.0;
}

class ProductVariantController extends GetxController {
  UnitController get unitC => Get.find<UnitController>();
  PriceController get priceC => Get.find<PriceController>();

  // ===================== STATE =====================
  // REMOVED: isLoadingVariants — was declared but never set, dead state

  // ===================== DATA =====================
  final productVariants = <VariantData>[].obs;
  final editVariantsTemp = <Map<String, dynamic>>[].obs;
  final variantsTemp = <Map<String, dynamic>>[].obs;
  final allVariants = <VariantData>[].obs;

  // ===================== SUMMARY CACHE =====================
  // ADDED: cache so getSummaryForProduct is not recomputed on every render/sort
  final _summaryCache = <String, ProductSummary>{};

  void invalidateSummaryCache() => _summaryCache.clear();

  // ===================== ADD VARIANT FORM =====================
  final variantNameC = TextEditingController();
  final variantStockC = TextEditingController();
  final variantCrisisStockC = TextEditingController();
  final variantBarcodeC = TextEditingController();
  final selectedUnitId = ''.obs;

  // ===================== EDIT VARIANT STATE =====================
  final dialogUnitId = ''.obs;
  final dialogNameC = TextEditingController();
  final dialogStockC = TextEditingController();
  final dialogCrisisStockC = TextEditingController();
  final dialogBarcodeC = TextEditingController();

  // ===================== DIRTY TRACKING — ADD VARIANT FORM =====================
  String _snapName = '';
  String _snapStock = '';
  String _snapCrisisStock = '';
  String _snapBarcode = '';
  String _snapUnitId = '';
  Map<String, bool> _snapPricesEnabled = {};
  Map<String, String> _snapPricesValue = {};
  VoidCallback? _variantDirtyListener;

  void takeVariantSnapshot() {
    _snapName = variantNameC.text;
    _snapStock = variantStockC.text;
    _snapCrisisStock = variantCrisisStockC.text;
    _snapBarcode = variantBarcodeC.text;
    _snapUnitId = selectedUnitId.value;
    _snapPricesEnabled = {
      for (var e in priceC.formPrices.entries)
        e.key: e.value['enabled'] as bool? ?? false,
    };
    _snapPricesValue = {
      for (var e in priceC.priceControllers.entries) e.key: e.value.text,
    };
  }

  void checkVariantDirty(ProductController productC) {
    final pricesChanged = priceC.formPrices.keys.any((id) {
      final enabledChanged =
          (priceC.formPrices[id]?['enabled'] as bool? ?? false) !=
          (_snapPricesEnabled[id] ?? false);
      final valueChanged =
          (priceC.priceControllers[id]?.text ?? '') !=
          (_snapPricesValue[id] ?? '');
      return enabledChanged || valueChanged;
    });

    productC.isDirty.value =
        variantNameC.text != _snapName ||
        variantStockC.text != _snapStock ||
        variantCrisisStockC.text != _snapCrisisStock ||
        variantBarcodeC.text != _snapBarcode ||
        selectedUnitId.value != _snapUnitId ||
        pricesChanged;
  }

  Worker? _unitIdWorker;

  void listenVariantFormChanges(ProductController productC) {
    if (_variantDirtyListener != null) {
      for (final ctrl in [
        variantNameC,
        variantStockC,
        variantCrisisStockC,
        variantBarcodeC,
      ]) {
        ctrl.removeListener(_variantDirtyListener!);
      }
      for (final ctrl in priceC.priceControllers.values) {
        ctrl.removeListener(_variantDirtyListener!);
      }
    }

    _variantDirtyListener = () => checkVariantDirty(productC);

    for (final ctrl in [
      variantNameC,
      variantStockC,
      variantCrisisStockC,
      variantBarcodeC,
    ]) {
      ctrl.addListener(_variantDirtyListener!);
    }
    for (final ctrl in priceC.priceControllers.values) {
      ctrl.addListener(_variantDirtyListener!);
    }

    _unitIdWorker?.dispose();
    _unitIdWorker = ever(selectedUnitId, (_) => checkVariantDirty(productC));
  }

  void _removeVariantListeners() {
    if (_variantDirtyListener == null) return;
    for (final ctrl in [
      variantNameC,
      variantStockC,
      variantCrisisStockC,
      variantBarcodeC,
    ]) {
      ctrl.removeListener(_variantDirtyListener!);
    }
    for (final ctrl in priceC.priceControllers.values) {
      ctrl.removeListener(_variantDirtyListener!);
    }
    _variantDirtyListener = null;
  }

  // ===================== DIRTY TRACKING — EDIT VARIANT =====================
  Map<String, dynamic>? _editVariantSnapshot;

  void prepareEditVariant(int index) {
    if (index < 0 || index >= editVariantsTemp.length) return;

    _editVariantSnapshot = Map<String, dynamic>.from(editVariantsTemp[index]);

    final v = editVariantsTemp[index];
    dialogNameC.text = v['name']?.toString() ?? '';
    dialogStockC.text = v['stock_qty']?.toString() ?? '0';
    dialogCrisisStockC.text = v['crisis_stock']?.toString() ?? '0';
    dialogBarcodeC.text = v['barcode']?.toString() ?? '';
    dialogUnitId.value = v['unit_id']?.toString() ?? '';

    priceC.initDialogPrices(
      priceListMasterList: priceC.priceListMaster,
      existingPrices: v['prices'] as List?,
    );
  }

  void cancelEditVariant(int index) {
    if (_editVariantSnapshot == null) return;
    if (index >= 0 && index < editVariantsTemp.length) {
      editVariantsTemp[index] = _editVariantSnapshot!;
      editVariantsTemp.refresh();
    }
    _editVariantSnapshot = null;
  }

  // ===================== PRICE VALIDATION =====================
  // ADDED: minimal 1 price list harus aktif + terisi angka > 0, baik pas
  // nambah variant baru maupun pas edit. Dipakai bareng di
  // addVariantFromForm() dan saveEditVariant() biar aturannya konsisten.
  bool _hasAtLeastOnePrice({required bool isDialog}) {
    final priceMap = isDialog ? priceC.dialogPrices : priceC.formPrices;
    final priceControllers = isDialog
        ? priceC.dialogPriceC
        : priceC.priceControllers;

    return priceC.priceListMaster.any((pl) {
      final enabled = priceMap[pl.id]?['enabled'] as bool? ?? false;
      if (!enabled) return false;
      final raw = priceControllers[pl.id]?.text.replaceAll('.', '') ?? '';
      final value = double.tryParse(raw) ?? 0;
      return value > 0;
    });
  }

  bool saveEditVariant(int index) {
    if (index < 0 || index >= editVariantsTemp.length) return false;

    if (!_hasAtLeastOnePrice(isDialog: true)) {
      AppToast.show('Aktifkan minimal 1 harga price list');
      return false;
    }

    // Build a lookup map once instead of scanning on every iteration
    final existingPricesById = <String, dynamic>{};
    for (final e in (editVariantsTemp[index]['prices'] as List? ?? [])) {
      final key = (e['price_list_id']?.toString() ?? '');
      if (key.isNotEmpty) existingPricesById[key] = e;
    }

    final newPrices = priceC.priceListMaster.fold<List<Map<String, dynamic>>>(
      [],
      (list, pl) {
        final entry = priceC.dialogPrices[pl.id];
        final enabled = entry?['enabled'] as bool? ?? false;
        final val = (priceC.dialogPriceC[pl.id]?.text.trim() ?? '').replaceAll(
          '.',
          '',
        );
        if (!enabled || val.isEmpty) return list;

        // O(1) lookup instead of O(N) firstWhereOrNull
        final oldPrice = existingPricesById[pl.id];

        return list..add({
          'id': oldPrice?['id'] ?? '',
          'price_list_id': pl.id,
          'price': val,
        });
      },
    );

    editVariantsTemp[index] = {
      ...editVariantsTemp[index],
      'name': dialogNameC.text.trim(),
      'stock_qty': int.tryParse(dialogStockC.text.trim()) ?? 0,
      'crisis_stock': int.tryParse(dialogCrisisStockC.text.trim()) ?? 0,
      'barcode': dialogBarcodeC.text.trim().isEmpty
          ? null
          : dialogBarcodeC.text.trim(),
      'unit_id': dialogUnitId.value,
      'unit_name':
          unitC.unitList
              .firstWhereOrNull((u) => u.id == dialogUnitId.value)
              ?.name ??
          '',
      'prices': newPrices,
      '_dirty': true,
    };

    _editVariantSnapshot = null;
    editVariantsTemp.refresh();
    AppToast.show('Klik Simpan untuk menyimpan');
    // NOTE: navigation removed from here — this is a controller method,
    // not a UI layer. Popping the variant form is handled by the caller
    // (variant_form_page.dart's onSave), otherwise we get a double-pop
    // that also closes the Edit Product page underneath it.
    return true;
  }

  // ===================== LIFECYCLE =====================
  @override
  void onClose() {
    _removeVariantListeners();
    _unitIdWorker?.dispose();
    variantNameC.dispose();
    variantStockC.dispose();
    variantCrisisStockC.dispose();
    variantBarcodeC.dispose();
    dialogNameC.dispose();
    dialogStockC.dispose();
    dialogCrisisStockC.dispose();
    dialogBarcodeC.dispose();
    super.onClose();
  }

  // ===================== FETCH =====================
  // CHANGED: cache-first (Pola B, sama kayak fetchProducts() &
  // priceC.fetchPrices()) — render instan dari cache kalau ada, TAPI
  // tetep lanjut fetch fresh di background. TTL sengaja pendek
  // (CacheKeys.stockPriceTtl) karena stok bisa berubah kapan aja (ada
  // transaksi masuk dll) — cache di sini cuma buat "instant paint" pas
  // buka halaman, bukan sumber kebenaran.
  Future<void> fetchAllVariants({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cached = CacheService.instance.get(
        CacheKeys.allVariants,
        ttl: CacheKeys.stockPriceTtl,
      );
      if (cached != null) {
        // FIX: paksa jalur cache-hit gak pernah 100% sinkron — nyegah
        // crash build-phase kalau dipanggil dari initState() page.
        await Future.microtask(() {});
        allVariants.assignAll(
          (cached as List).map((e) => VariantData.fromJson(e)).toList(),
        );
        invalidateSummaryCache();
        // sengaja gak return — lanjut fetch fresh di background biar
        // stok ke-update walau tampilan udah instant dari cache
      }
    }

    final res = await ProductService.getAllVariants();
    if (res.statusCode == 200) {
      final jsonData = json.decode(res.body);
      final list = (jsonData['data'] as List? ?? [])
          .map((e) => VariantData.fromJson(e))
          .toList();
      allVariants.assignAll(list);
      // ADDED: invalidate cache whenever variants are refreshed
      invalidateSummaryCache();
      await CacheService.instance.set(
        CacheKeys.allVariants,
        list.map((v) => v.toJson()).toList(),
      );
    }
  }

  Future<void> loadEditVariants() async {
    editVariantsTemp.assignAll(
      productVariants.map((v) {
        final prices = priceC.priceList
            .where((p) => p.productVariantId == v.id)
            .map(
              (p) => {
                'id': p.id,
                'price_list_id': p.priceListId,
                'price': p.price,
              },
            )
            .toList();

        return {
          'id': v.id,
          'name': v.name,
          'stock_qty': v.stockQty,
          'crisis_stock': v.crisisStock,
          'barcode': v.barcode ?? '',
          'unit_id': resolveUnitId(v),
          'unit_name': v.unitName ?? '',
          'is_base_unit': v.isBaseUnit == 1,
          'conversion_factor':
              double.tryParse(v.conversionFactor.toString()) ?? 1.0,
          'prices': prices,
        };
      }).toList(),
    );

    initPriceControllers();
  }

  void resetVariants() {
    variantsTemp.clear();
    editVariantsTemp.clear();
    productVariants.clear();
    invalidateSummaryCache(); // ADDED: clear cache on full reset
    clearVariantForm();
  }

  // ===================== ADD VARIANT FORM =====================
  void initPriceControllers() {
    priceC.initPriceControllers();
  }

  void clearVariantForm({ProductController? productC}) {
    _removeVariantListeners();
    variantNameC.clear();
    variantStockC.clear();
    variantCrisisStockC.clear();
    variantBarcodeC.clear();
    selectedUnitId.value = '';
    priceC.clearFormPrices(productC: productC);
  }

  bool addVariantFromForm({required bool isEditMode}) {
    final stock = int.tryParse(variantStockC.text);
    if (variantNameC.text.isEmpty ||
        stock == null ||
        selectedUnitId.value.isEmpty) {
      AppToast.show('Lengkapi data variant');
      return false;
    }

    // ADDED: minimal 1 price list harus aktif sebelum variant bisa disimpan
    if (!_hasAtLeastOnePrice(isDialog: false)) {
      AppToast.show('Aktifkan minimal 1 harga price list');
      return false;
    }

    final unit = unitC.unitList.firstWhere((u) => u.id == selectedUnitId.value);
    final prices = <Map<String, dynamic>>[];

    priceC.priceControllers.forEach((id, c) {
      final enabled = priceC.formPrices[id]?['enabled'] as bool? ?? false;
      final price = double.tryParse(c.text.replaceAll('.', ''));
      if (enabled && price != null && price > 0) {
        prices.add({'price_list_id': id, 'price': price});
      }
    });

    final newVariant = {
      'id': '',
      'name': variantNameC.text.trim(),
      'stock_qty': stock,
      'crisis_stock': int.tryParse(variantCrisisStockC.text.trim()) ?? 0,
      'barcode': variantBarcodeC.text.isEmpty
          ? null
          : variantBarcodeC.text.trim(),
      'unit_id': unit.id,
      'unit_name': unit.name,
      'is_base_unit': false,
      'conversion_factor': 1.0,
      'prices': prices,
    };

    if (isEditMode) {
      editVariantsTemp.add(newVariant);
    } else {
      variantsTemp.add(newVariant);
    }

    clearVariantForm();
    return true;
  }

  void removeTempVariant(int index, {required bool isEditMode}) {
    final list = isEditMode ? editVariantsTemp : variantsTemp;
    if (index >= 0 && index < list.length) list.removeAt(index);
  }

  Future<void> deleteVariant(int index, {required bool isEditMode}) async {
    final list = isEditMode ? editVariantsTemp : variantsTemp;
    if (index < 0 || index >= list.length) return;

    final variantId = list[index]['id']?.toString() ?? '';

    if (variantId.isEmpty) {
      list.removeAt(index);
      return;
    }

    final confirm = await AppDialog.confirm(
      title: 'Hapus Varian',
      content: 'Varian ini akan dihapus permanen. Lanjutkan?',
      confirmLabel: 'Hapus',
    );
    if (!confirm) return;

    final res = await ProductService.deleteVariant(variantId);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      list.removeAt(index);

      // FIX: prune allVariants & priceList lokal, bukan cuma clear cache.
      // Tanpa ini, getSummaryForProduct() masih hitung ulang dari data basi.
      allVariants.removeWhere((v) => v.id == variantId);
      priceC.priceList.removeWhere((p) => p.productVariantId == variantId);

      invalidateSummaryCache();

      // ADDED: invalidate persisted cache juga — bukan cuma Rx list di
      // memori. Tanpa ini, cold start berikutnya (dalam TTL 30 detik)
      // bisa sempet render varian yang udah dihapus sebelum background
      // refetch benerin lagi.
      await CacheService.instance.invalidate(CacheKeys.allVariants);
      await CacheService.instance.invalidate(CacheKeys.priceList);

      AppToast.show('Varian berhasil dihapus');
    } else {
      AppToast.show('Gagal menghapus varian');
    }
  }

  void togglePrice(
    String priceListId, {
    bool isDialog = false,
    ProductController? productC,
  }) {
    priceC.togglePrice(priceListId, isDialog: isDialog, productC: productC);
    if (productC != null && !isDialog) checkVariantDirty(productC);
  }

  // ===================== CRUD =====================
  Future<void> createVariantWithPrices({
    required String productId,
    required Map<String, dynamic> variantData,
  }) async {
    final res = await ProductService.createVariant(
      productId: productId,
      unitId: variantData['unit_id']?.toString() ?? '',
      name: variantData['name']?.toString() ?? '',
      stock: int.tryParse(variantData['stock_qty']?.toString() ?? '0') ?? 0,
      crisisStock:
          int.tryParse(variantData['crisis_stock']?.toString() ?? '0') ?? 0,
      barcode: variantData['barcode']?.toString().trim(),
      isBaseUnit: variantData['is_base_unit'] as bool? ?? false,
    );

    if (res.statusCode != 201) return;

    final newVariantId = json.decode(res.body)['data']['id']?.toString() ?? '';

    await Future.wait(
      (variantData['prices'] as List? ?? [])
          .where((p) {
            final plId = p['price_list_id']?.toString() ?? '';
            final price = double.tryParse(p['price']?.toString() ?? '0') ?? 0;
            return plId.isNotEmpty && price > 0;
          })
          .map(
            (p) => ProductService.createPrice(
              variantId: newVariantId,
              priceListId: p['price_list_id'].toString(),
              price: double.parse(p['price'].toString()),
            ),
          ),
    );
  }

  Future<void> updateExistingVariant(Map<String, dynamic> v) async {
    final variantId = v['id'].toString();
    final unitId = v['unit_id']?.toString() ?? '';
    final crisisStock =
        int.tryParse(v['crisis_stock']?.toString() ?? '0') ?? 0;
    final barcode = v['barcode']?.toString().trim() ?? '';
    final isBaseUnit = v['is_base_unit'] as bool? ?? false;

    if (unitId.isEmpty) return;

    final res = await ProductService.updateVariant(
      id: variantId,
      name: v['name']?.toString() ?? '',
      stock: int.tryParse(v['stock_qty']?.toString() ?? '0') ?? 0,
      crisisStock: crisisStock,
      unitId: unitId,
      barcode: barcode.isEmpty ? null : barcode,
      isBaseUnit: isBaseUnit,
    );

    if (res.statusCode < 200 || res.statusCode >= 300) return;

    await priceC.syncPrices(
      variantId: variantId,
      newPrices: List<Map<String, dynamic>>.from(v['prices'] ?? []),
    );
  }

  // ===================== HELPERS =====================
  String resolveUnitId(VariantData v) {
    final unitId = v.unitId?.toString().trim() ?? '';
    if (unitId.isNotEmpty && unitC.unitList.any((u) => u.id == unitId)) {
      return unitId;
    }
    if (v.unitName != null) {
      final match = unitC.unitList.firstWhereOrNull(
        (u) => u.name.toLowerCase() == v.unitName!.toLowerCase(),
      );
      if (match != null) return match.id;
    }
    return unitC.unitList.isNotEmpty ? unitC.unitList.first.id : '';
  }

  // ===================== PRODUCT SUMMARY =====================
  ProductSummary getSummaryForProduct(String productId) {
    return _summaryCache.putIfAbsent(
      productId,
      () => _computeSummary(productId),
    );
  }

  ProductSummary _computeSummary(String productId) {
    final variants = allVariants
        .where((v) => v.productId == productId)
        .toList();

    final totalStock = variants.fold<int>(0, (s, v) => s + v.stockQty);
    final isOutOfStock = variants.isNotEmpty && totalStock == 0;

    final normalPriceListId = priceC.priceListMaster
        .firstWhereOrNull((pl) => pl.code.toLowerCase() == 'normal')
        ?.id;

    final mainVariant =
        variants.firstWhereOrNull((v) => v.isBaseUnit == 1) ??
        variants.firstOrNull;

    final mainVariantPrices = mainVariant != null
        ? priceC.priceList
              .where((p) => p.productVariantId == mainVariant.id)
              .toList()
        : <PriceData>[];

    final rawPrice = mainVariantPrices.isEmpty
        ? '0'
        : ((normalPriceListId != null
                      ? mainVariantPrices.firstWhereOrNull(
                          (p) => p.priceListId == normalPriceListId,
                        )
                      : null) ??
                  mainVariantPrices.first)
              .price;

    // CHANGED: parse once here using the safe ID-locale parser, store as double
    final mainPriceValue = parseIdPrice(rawPrice);

    final additionalPriceCount = mainVariantPrices.length > 1
        ? mainVariantPrices.length - 1
        : 0;

    // ADDED: ambil crisis_stock dari varian utama (base unit), bukan
    // angka hardcode — beda produk bisa punya ambang stok kritis beda-beda
    // sesuai yang di-set lewat backend.
    final crisisStockThreshold = mainVariant?.crisisStock ?? 0;

    return ProductSummary(
      totalStock: totalStock,
      isOutOfStock: isOutOfStock,
      mainPriceValue: mainPriceValue,
      additionalPriceCount: additionalPriceCount,
      variantCount: variants.length,
      crisisStockThreshold: crisisStockThreshold,
    );
  }
}