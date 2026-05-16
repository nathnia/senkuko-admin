// lib/features/products/controllers/product_variant_controller.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:senkukoadmin/constant/app_toast.dart';
import 'package:senkukoadmin/constant/api_helper.dart';
import 'package:senkukoadmin/constant/currency_formatter.dart';
import 'package:senkukoadmin/features/products/models/product_price_model.dart';
import 'package:senkukoadmin/features/products/models/product_pricelist_model.dart';
import 'package:senkukoadmin/features/products/models/product_variant_model.dart';
import 'package:senkukoadmin/features/products/models/unit_model.dart';
import 'package:senkukoadmin/features/products/product_service.dart';

// ── Product summary — dipakai ProductCard ────────────────────────────────────

class ProductSummary {
  final int totalStock;
  final bool isOutOfStock;
  final String mainPrice;
  final int additionalPriceCount;

  const ProductSummary({
    required this.totalStock,
    required this.isOutOfStock,
    required this.mainPrice,
    required this.additionalPriceCount,
  });
}

class ProductVariantController extends GetxController {
  // ===================== DATA =====================
  final unitList = <UnitData>[].obs;
  final priceList = <PriceData>[].obs;
  final priceListMaster = <PricelistData>[].obs;
  final productVariants = <VariantData>[].obs;
  final editVariantsTemp = <Map<String, dynamic>>[].obs;
  final variantsTemp = <Map<String, dynamic>>[].obs;
  final allVariants = <VariantData>[].obs;

  // ===================== ADD VARIANT FORM =====================
  final variantNameC = TextEditingController();
  final variantStockC = TextEditingController();
  final variantBarcodeC = TextEditingController();
  final selectedUnitId = ''.obs;
  final Map<String, TextEditingController> priceControllers = {};

  // ===================== EDIT VARIANT STATE =====================
  final dialogUnitId = ''.obs;
  final dialogPrices = <String, Map<String, dynamic>>{}.obs;
  final formPrices = <String, Map<String, dynamic>>{}.obs;
  final dialogNameC = TextEditingController();
  final dialogStockC = TextEditingController();
  final dialogBarcodeC = TextEditingController();
  final Map<String, TextEditingController> dialogPriceC = {};

  // ===================== LIFECYCLE =====================
  @override
  void onInit() {
    super.onInit();
    _loadInitialData();
  }

  @override
  void onClose() {
    variantNameC.dispose();
    variantStockC.dispose();
    variantBarcodeC.dispose();
    dialogNameC.dispose();
    dialogStockC.dispose();
    dialogBarcodeC.dispose();
    for (var c in [...priceControllers.values, ...dialogPriceC.values]) {
      c.dispose();
    }
    super.onClose();
  }

  // ===================== INIT =====================
  Future<void> _loadInitialData() async {
    try {
      await Future.wait([
        fetchUnits(),
        fetchPrices(),
        fetchPriceLists(),
        fetchAllVariants(),
      ]);
    } catch (e) {
      AppToast.error('Gagal memuat data variant');
    }
  }

  // ===================== FETCH =====================
  Future<void> fetchUnits() async {
    final res = await ProductService.getUnits();
    if (res.statusCode == 200) {
      final jsonData = json.decode(res.body);
      unitList.assignAll(
        (jsonData['data'] as List? ?? [])
            .map((e) => UnitData.fromJson(e))
            .toList(),
      );
    }
  }

  Future<void> fetchPrices() async {
    final res = await ProductService.getPrices();
    if (res.statusCode == 200) {
      priceList.assignAll(productPriceModelFromJson(res.body).data);
    }
  }

  Future<void> fetchPriceLists() async {
    final res = await ProductService.getPriceLists();
    if (res.statusCode == 200) {
      priceListMaster.assignAll(priceListModelFromJson(res.body).data);
    }
  }

  Future<void> fetchAllVariants() async {
    final res = await ProductService.getAllVariants();
    if (res.statusCode == 200) {
      final jsonData = json.decode(res.body);
      allVariants.assignAll(
        (jsonData['data'] as List? ?? [])
            .map((e) => VariantData.fromJson(e))
            .toList(),
      );
    }
  }

  Future<void> loadEditVariants() async {
    editVariantsTemp.assignAll(
      productVariants.map((v) {
        final prices = priceList
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
          'barcode': v.barcode ?? '',
          'unit_id': resolveUnitId(v),
          'unit_name': v.unitName ?? '',
          'is_base_unit': v.isBaseUnit == 1,
          'prices': prices,
        };
      }).toList(),
    );

    initPriceControllers();
  }

  // ===================== PRICE LIST SORTED =====================
  // 'normal' selalu paling atas, sisanya urutan asli dari API
  List<PricelistData> get sortedPriceListMaster {
    return [...priceListMaster]..sort((a, b) {
      if (a.code.toLowerCase() == 'normal') return -1;
      if (b.code.toLowerCase() == 'normal') return 1;
      return 0;
    });
  }

  // ===================== ADD VARIANT FORM =====================
  void initPriceControllers() {
    for (var p in sortedPriceListMaster) {
      priceControllers.putIfAbsent(p.id, () => TextEditingController());
      formPrices.putIfAbsent(p.id, () => {'enabled': false});
    }
  }

  void clearVariantForm() {
    variantNameC.clear();
    variantStockC.clear();
    variantBarcodeC.clear();
    selectedUnitId.value = '';
    for (var c in priceControllers.values) {
      c.clear();
    }
    for (var id in formPrices.keys) {
      formPrices[id] = {'enabled': false};
    }
    formPrices.refresh();
  }

  void addVariantFromForm({required bool isEditMode}) {
    final stock = int.tryParse(variantStockC.text);
    if (variantNameC.text.isEmpty ||
        stock == null ||
        selectedUnitId.value.isEmpty) {
      AppToast.error('Lengkapi data variant');
      return;
    }

    final unit = unitList.firstWhere((u) => u.id == selectedUnitId.value);
    final prices = <Map<String, dynamic>>[];

    priceControllers.forEach((id, c) {
      final enabled = formPrices[id]?['enabled'] as bool? ?? false;
      final price = double.tryParse(c.text.replaceAll('.', ''));
      if (enabled && price != null && price > 0) {
        prices.add({'price_list_id': id, 'price': price});
      }
    });

    final newVariant = {
      'id': '',
      'name': variantNameC.text.trim(),
      'stock_qty': stock,
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
  }

  void removeTempVariant(int index, {required bool isEditMode}) {
    final list = isEditMode ? editVariantsTemp : variantsTemp;
    if (index >= 0 && index < list.length) list.removeAt(index);
  }

  // ===================== EDIT VARIANT =====================
  void prepareEditVariant(int index) {
    if (index < 0 || index >= editVariantsTemp.length) return;

    final v = editVariantsTemp[index];
    dialogNameC.text = v['name']?.toString() ?? '';
    dialogStockC.text = v['stock_qty']?.toString() ?? '0';
    dialogBarcodeC.text = v['barcode']?.toString() ?? '';
    dialogUnitId.value = v['unit_id']?.toString() ?? '';

    for (var c in dialogPriceC.values) {
      c.dispose();
    }
    dialogPriceC.clear();
    dialogPrices.clear();

    for (var pl in sortedPriceListMaster) {
      final existing = (v['prices'] as List?)?.firstWhereOrNull(
        (e) => (e['price_list_id']?.toString() ?? '') == pl.id,
      );

      dialogPrices[pl.id] = {
        'enabled': existing != null,
        'price': existing?['price']?.toString() ?? '',
      };

      dialogPriceC[pl.id] = TextEditingController(
        text: existing != null
            ? CurrencyFormatter.format(
                existing['price']?.toString() ?? '0',
              ).replaceAll('Rp', '').replaceAll(' ', '').trim()
            : '',
      );
    }
    dialogPrices.refresh();
  }

  void togglePrice(String priceListId, {bool isDialog = false}) {
    final prices = isDialog ? dialogPrices : formPrices;
    final controllers = isDialog ? dialogPriceC : priceControllers;

    final current = prices[priceListId];
    if (current == null) return;

    final nowEnabled = !(current['enabled'] as bool);
    prices[priceListId] = {
      'enabled': nowEnabled,
      if (isDialog) 'price': current['price'],
    };
    if (!nowEnabled) controllers[priceListId]?.clear();
    prices.refresh();
  }

  void saveEditVariant(int index) {
    if (index < 0 || index >= editVariantsTemp.length) return;

    final newPrices = sortedPriceListMaster.fold<List<Map<String, dynamic>>>(
      [],
      (list, pl) {
        final entry = dialogPrices[pl.id];
        final enabled = entry?['enabled'] as bool? ?? false;
        final val = (dialogPriceC[pl.id]?.text.trim() ?? '').replaceAll(
          '.',
          '',
        );
        if (!enabled || val.isEmpty) return list;

        final oldPrice = (editVariantsTemp[index]['prices'] as List?)
            ?.firstWhereOrNull(
              (e) => (e['price_list_id']?.toString() ?? '') == pl.id,
            );

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
      'barcode': dialogBarcodeC.text.trim().isEmpty
          ? null
          : dialogBarcodeC.text.trim(),
      'unit_id': dialogUnitId.value,
      'unit_name':
          unitList.firstWhereOrNull((u) => u.id == dialogUnitId.value)?.name ??
          '',
      'prices': newPrices,
    };

    editVariantsTemp.refresh();
    Get.back();
    AppToast.info('Varian diubah. Tekan Simpan.');
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
    final barcode = v['barcode']?.toString().trim() ?? '';
    final isBaseUnit = v['is_base_unit'] as bool? ?? false;

    if (unitId.isEmpty) return;

    final res = await ProductService.updateVariant(
      id: variantId,
      name: v['name']?.toString() ?? '',
      stock: int.tryParse(v['stock_qty']?.toString() ?? '0') ?? 0,
      unitId: unitId,
      barcode: barcode.isEmpty ? null : barcode,
      isBaseUnit: isBaseUnit,
    );

    if (res.statusCode < 200 || res.statusCode >= 300) return;

    await _syncPrices(
      variantId: variantId,
      newPrices: List<Map<String, dynamic>>.from(v['prices'] ?? []),
    );
  }

  // ===================== PRICE SYNC =====================
  Future<List<Map<String, dynamic>>> loadPricesForVariant(
    String variantId,
  ) async {
    try {
      final res = await ProductService.getPricesByVariant(variantId);
      if (res.statusCode != 200) return [];

      final jsonData = json.decode(res.body);
      final dynamic data = jsonData['data'];
      final List rawList = data is Map
          ? (data['prices'] ?? [])
          : (data as List? ?? []);

      return rawList.map((e) {
        final m = Map<String, dynamic>.from(e as Map);
        return {
          'id': m['id']?.toString() ?? '',
          'price_list_id': m['price_list_id']?.toString() ?? '',
          'price':
              double.tryParse(
                m['price']?.toString() ?? '0',
              )?.toStringAsFixed(0) ??
              '0',
        };
      }).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> _syncPrices({
    required String variantId,
    required List<Map<String, dynamic>> newPrices,
  }) async {
    final existingPrices = await loadPricesForVariant(variantId);

    final existingMap = <String, Map<String, dynamic>>{
      for (var ep in existingPrices)
        if ((ep['price_list_id'] ?? '').isNotEmpty) ep['price_list_id']: ep,
    };

    final newPriceListIds = newPrices
        .map((p) => p['price_list_id']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toSet();

    for (var np in newPrices) {
      final plId = np['price_list_id']?.toString() ?? '';
      final newValue = double.tryParse(np['price']?.toString() ?? '0') ?? 0;
      if (plId.isEmpty || newValue <= 0) continue;

      if (existingMap.containsKey(plId)) {
        final existing = existingMap[plId]!;
        final existingId = existing['id']?.toString() ?? '';
        final oldValue =
            double.tryParse(existing['price']?.toString() ?? '0') ?? 0;
        if (existingId.isNotEmpty && oldValue != newValue) {
          await ProductService.updatePrice(
            priceId: existingId,
            priceListId: plId,
            price: newValue,
          );
        }
      } else {
        await ProductService.createPrice(
          variantId: variantId,
          priceListId: plId,
          price: newValue,
        );
      }
    }

    if (existingPrices.length <= 1) return;
    for (var ep in existingPrices) {
      final plId = ep['price_list_id']?.toString() ?? '';
      final priceId = ep['id']?.toString() ?? '';
      if (newPriceListIds.contains(plId) || priceId.isEmpty) continue;
      await ProductService.deletePrice(priceId);
    }
  }

  // ===================== PRODUCT SUMMARY =====================
  ProductSummary getSummaryForProduct(String productId) {
    final variants = allVariants
        .where((v) => v.productId == productId)
        .toList();

    final totalStock = variants.fold<int>(0, (s, v) => s + v.stockQty);
    final isOutOfStock = variants.isNotEmpty && totalStock == 0;

    final variantIds = variants.map((v) => v.id).toSet();
    final productPrices = priceList
        .where((p) => variantIds.contains(p.productVariantId))
        .toList();

    final normalPriceListId = priceListMaster
        .firstWhereOrNull((pl) => pl.code.toLowerCase() == 'normal')
        ?.id;

    final mainPrice = productPrices.isEmpty
        ? '0'
        : ((normalPriceListId != null
                      ? productPrices.firstWhereOrNull(
                          (p) => p.priceListId == normalPriceListId,
                        )
                      : null) ??
                  productPrices.first)
              .price;

    final additionalPriceCount = productPrices.length > 1
        ? productPrices.length - 1
        : 0;

    return ProductSummary(
      totalStock: totalStock,
      isOutOfStock: isOutOfStock,
      mainPrice: mainPrice,
      additionalPriceCount: additionalPriceCount,
    );
  }

  // ===================== PRICE DISPLAY HELPERS =====================
  List<PriceData> getPricesByVariant(String variantId) =>
      priceList.where((e) => e.productVariantId == variantId).toList();

  // ===================== UNIT HELPERS =====================
  Future<String?> createUnit(String name, String symbol) async {
    if (name.isEmpty || symbol.isEmpty) {
      AppToast.error('Nama & symbol wajib');
      return null;
    }
    if (unitList.any((u) => u.symbol == symbol)) {
      AppToast.error('Symbol sudah ada');
      return null;
    }
    try {
      final res = await ProductService.createUnit(name: name, symbol: symbol);
      if (res.statusCode == 201) {
        await fetchUnits();
        AppToast.success('Unit ditambahkan');
        return json.decode(res.body)['data']['id'];
      }
      AppToast.error('Gagal tambah unit');
    } catch (e) {
      AppToast.error('Terjadi kesalahan');
    }
    return null;
  }

  Future<void> deleteUnit(String id) async {
    try {
      final res = await ProductService.deleteUnit(id);
      if (res.statusCode == 200) {
        AppToast.success('Unit berhasil dihapus');
        await fetchUnits();
      } else {
        AppToast.error(ApiHelper.parseError(res.body));
      }
    } catch (e) {
      AppToast.error('Terjadi kesalahan');
    }
  }

  // ===================== HELPERS =====================
  String resolveUnitId(VariantData v) {
    final unitId = v.unitId?.toString().trim() ?? '';
    if (unitId.isNotEmpty && unitList.any((u) => u.id == unitId)) return unitId;
    if (v.unitName != null) {
      final match = unitList.firstWhereOrNull(
        (u) => u.name.toLowerCase() == v.unitName!.toLowerCase(),
      );
      if (match != null) return match.id;
    }
    return unitList.isNotEmpty ? unitList.first.id : '';
  }

  // ===================== DETAIL HELPERS =====================
  List<Map<String, dynamic>> get detailVariantMaps {
    return productVariants.map((v) {
      final prices = getPricesByVariant(
        v.id,
      ).map((p) => {'price_list_id': p.priceListId, 'price': p.price}).toList();

      return {
        'id': v.id,
        'name': v.name,
        'stock_qty': v.stockQty,
        'unit_name': v.unitSymbol ?? v.unitName ?? '',
        'barcode': v.barcode ?? '',
        'prices': prices,
      };
    }).toList();
  }

  // Di dalam class ProductVariantController

  /// Helper untuk mendapatkan daftar harga yang sudah rapi + nama price list
  List<Map<String, dynamic>> getFormattedPrices(Map<String, dynamic> variant) {
    final prices = variant['prices'] as List? ?? [];

    return prices.map((p) {
      final priceListId = p['price_list_id']?.toString() ?? '';

      final priceList = sortedPriceListMaster.firstWhereOrNull(
        (pl) => pl.id == priceListId,
      );

      return {
        'price_list_id': priceListId,
        'price_list_name': priceList?.name ?? 'Unknown',
        'price': p['price']?.toString() ?? '0',
        'price_raw': p['price'], // kalau butuh number
      };
    }).toList();
  }

  /// Optional: Kalau mau urutkan sesuai sortedPriceListMaster
  List<Map<String, dynamic>> getFormattedPricesSorted(
    Map<String, dynamic> variant,
  ) {
    final rawPrices = getFormattedPrices(variant);

    // Buat map untuk lookup cepat
    final priceMap = {for (var p in rawPrices) p['price_list_id']: p};

    return sortedPriceListMaster
        .where((pl) => priceMap.containsKey(pl.id))
        .map((pl) => priceMap[pl.id]!)
        .toList();
  }
}
