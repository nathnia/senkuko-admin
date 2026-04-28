import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:senkukoadmin/features/products/models/product_price_model.dart';
import 'package:senkukoadmin/features/products/models/product_pricelist_model.dart';
import 'package:senkukoadmin/features/products/models/product_variant_model.dart';
import 'package:senkukoadmin/features/products/models/unit_model.dart';
import 'package:senkukoadmin/features/products/product_service.dart';

class ProductVariantController extends GetxController {
  // ===================== STATE =====================
  final isLoadingVariants = false.obs;

  // ===================== DATA =====================
  final unitList = <UnitData>[].obs;
  final priceList = <PriceData>[].obs;
  final priceListMaster = <PricelistData>[].obs;
  final productVariants = <VariantData>[].obs;
  final editVariantsTemp = <Map<String, dynamic>>[].obs;
  final variantsTemp = <Map<String, dynamic>>[].obs;

  // ===================== ADD VARIANT FORM =====================
  final variantNameC = TextEditingController();
  final variantStockC = TextEditingController();
  final variantBarcodeC = TextEditingController();
  final selectedUnitId = ''.obs;
  final Map<String, TextEditingController> priceControllers = {};

  // ===================== EDIT VARIANT DIALOG STATE =====================
  // Semua state ini di-observe oleh EditVariantDialog (view)
  // Tidak ada StatefulBuilder, tidak ada Get.dialog di sini
  final dialogUnitId = ''.obs;

  // key: price_list_id → {enabled: bool, price: String}
  final dialogPrices = <String, Map<String, dynamic>>{}.obs;
  // key: price_list_id → {enabled: bool}
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
    // Add variant form
    variantNameC.dispose();
    variantStockC.dispose();
    variantBarcodeC.dispose();
    for (var c in priceControllers.values) {
      c.dispose();
    }

    // Edit dialog
    dialogNameC.dispose();
    dialogStockC.dispose();
    dialogBarcodeC.dispose();
    for (var c in dialogPriceC.values) {
      c.dispose();
    }

    super.onClose();
  }

  // ===================== INIT =====================
  Future<void> _loadInitialData() async {
    isLoadingVariants.value = true;
    try {
      await Future.wait([fetchUnits(), fetchPrices(), fetchPriceLists()]);
    } catch (e) {
      Get.snackbar('Error', 'Gagal memuat data variant');
    } finally {
      isLoadingVariants.value = false;
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

  Future<void> loadEditVariants() async {
    editVariantsTemp.clear();

    for (var v in productVariants) {
      // ← Tidak perlu fetch! Pakai data yang sudah ada
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

      editVariantsTemp.add({
        'id': v.id,
        'name': v.name,
        'stock_qty': v.stockQty,
        'barcode': v.barcode ?? '',
        'unit_id': resolveUnitId(v),
        'unit_name': v.unitName ?? '',
        'is_base_unit': v.isBaseUnit == 1,
        'conversion_factor':
            double.tryParse(v.conversionFactor.toString()) ?? 1.0,
        'prices': prices,
      });
    }

    editVariantsTemp.refresh();
    initPriceControllers();
  }

  void resetVariants() {
    variantsTemp.clear();
    editVariantsTemp.clear();
    productVariants.clear();
    clearVariantForm();
  }

  // ===================== ADD VARIANT FORM =====================
  void initPriceControllers() {
    for (var p in priceListMaster) {
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
      Get.snackbar('Error', 'Lengkapi data variant');
      return;
    }

    final unit = unitList.firstWhere((u) => u.id == selectedUnitId.value);
    final prices = <Map<String, dynamic>>[];

    priceControllers.forEach((id, c) {
      final enabled = formPrices[id]?['enabled'] as bool? ?? false;
      final price = double.tryParse(c.text.replaceAll('.', '')); // strip titik
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

  // ===================== EDIT VARIANT DIALOG STATE =====================
  // Dipanggil dari view SEBELUM Get.dialog(EditVariantDialog())
  void prepareEditVariantDialog(int index) {
    if (index < 0 || index >= editVariantsTemp.length) return;

    final v = editVariantsTemp[index];

    dialogNameC.text = v['name']?.toString() ?? '';
    dialogStockC.text = v['stock_qty']?.toString() ?? '0';
    dialogBarcodeC.text = v['barcode']?.toString() ?? '';
    dialogUnitId.value = v['unit_id']?.toString() ?? '';

    // Dispose & rebuild dialog price controllers
    for (var c in dialogPriceC.values) {
      c.dispose();
    }
    dialogPriceC.clear();
    dialogPrices.clear();

    for (var pl in priceListMaster) {
      final existing = (v['prices'] as List?)?.firstWhereOrNull(
        (e) => (e['price_list_id']?.toString() ?? '') == pl.id,
      );
      dialogPrices[pl.id] = {
        'enabled': existing != null,
        'price': existing?['price']?.toString() ?? '',
      };
      dialogPriceC[pl.id] = TextEditingController(
        text: existing?['price']?.toString() ?? '',
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

  // // Dipanggil dari view saat toggle checkbox/icon harga
  // void toggleDialogPrice(String priceListId) {
  //   final current = dialogPrices[priceListId];
  //   if (current == null) return;
  //   final nowEnabled = !(current['enabled'] as bool);
  //   dialogPrices[priceListId] = {
  //     'enabled': nowEnabled,
  //     'price': current['price'],
  //   };
  //   if (!nowEnabled) dialogPriceC[priceListId]?.clear();
  //   dialogPrices.refresh();
  // }

  // Dipanggil dari view saat user tekan Simpan di dialog
  void saveEditVariantDialog(int index) {
    if (index < 0 || index >= editVariantsTemp.length) return;

    final newPrices = <Map<String, dynamic>>[];
    for (var pl in priceListMaster) {
      final entry = dialogPrices[pl.id];
      final enabled = entry?['enabled'] as bool? ?? false;
      final val = (dialogPriceC[pl.id]?.text.trim() ?? '').replaceAll('.', '');
      if (!enabled || val.isEmpty) continue;

      final oldPrice = (editVariantsTemp[index]['prices'] as List?)
          ?.firstWhereOrNull(
            (e) => (e['price_list_id']?.toString() ?? '') == pl.id,
          );

      newPrices.add({
        'id': oldPrice?['id'] ?? '',
        'price_list_id': pl.id,
        'price': val,
      });
    }

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
    Get.snackbar(
      'Tersimpan',
      'Klik Simpan Perubahan untuk menyimpan ke server',
      backgroundColor: Colors.blue,
      colorText: Colors.white,
    );
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

    if (res.statusCode != 201) {
      return;
    }

    final newVariantId = json.decode(res.body)['data']['id']?.toString() ?? '';

    for (var p in (variantData['prices'] as List? ?? [])) {
      final plId = p['price_list_id']?.toString() ?? '';
      final price = double.tryParse(p['price']?.toString() ?? '0') ?? 0;
      if (plId.isNotEmpty && price > 0) {
        await ProductService.createPrice(
          variantId: newVariantId,
          priceListId: plId,
          price: price,
        );
      }
    }
  }

  Future<void> updateExistingVariant(Map<String, dynamic> v) async {
    final variantId = v['id'].toString();
    final unitId = v['unit_id']?.toString() ?? '';
    final barcode = v['barcode']?.toString().trim() ?? '';
    final isBaseUnit = v['is_base_unit'] as bool? ?? false;

    if (unitId.isEmpty) {
      return;
    }

    final res = await ProductService.updateVariant(
      id: variantId,
      name: v['name']?.toString() ?? '',
      stock: int.tryParse(v['stock_qty']?.toString() ?? '0') ?? 0,
      unitId: unitId,
      barcode: barcode.isEmpty ? null : barcode,
      isBaseUnit: isBaseUnit,
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      return;
    }

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
        final createRes = await ProductService.createPrice(
          variantId: variantId,
          priceListId: plId,
          price: newValue,
        );
        debugPrint(
          createRes.statusCode == 201
              ? '   ✅ Create harga baru $plId: $newValue'
              : '   ❌ Gagal create harga $plId: ${createRes.body}',
        );
      }
    }

    for (var ep in existingPrices) {
      final plId = ep['price_list_id']?.toString() ?? '';
      final priceId = ep['id']?.toString() ?? '';
      if (newPriceListIds.contains(plId) || priceId.isEmpty) continue;
      if (existingPrices.length == 1) {
        continue;
      }
      final deleteRes = await ProductService.deletePrice(priceId);
      debugPrint(
        deleteRes.statusCode == 200
            ? '   🗑 Hapus harga $plId ($priceId)'
            : '   ❌ Gagal hapus $priceId: ${deleteRes.body}',
      );
    }
  }

  // void toggleFormPrice(String priceListId) {
  //   final current = formPrices[priceListId];
  //   if (current == null) return;
  //   final nowEnabled = !(current['enabled'] as bool);
  //   formPrices[priceListId] = {'enabled': nowEnabled};
  //   if (!nowEnabled) priceControllers[priceListId]?.clear();
  //   formPrices.refresh();
  // }

  // ===================== PRICE DISPLAY HELPERS =====================
  List<PriceData> getPricesByVariant(String variantId) {
    return priceList.where((e) => e.productVariantId == variantId).toList();
  }

  // ===================== UNIT HELPERS =====================
  Future<String?> createUnit(String name, String symbol) async {
    if (name.isEmpty || symbol.isEmpty) {
      Get.snackbar('Error', 'Nama & symbol wajib');
      return null;
    }
    if (unitList.any((u) => u.symbol == symbol)) {
      Get.snackbar('Error', 'Symbol sudah ada');
      return null;
    }
    try {
      final res = await ProductService.createUnit(name: name, symbol: symbol);
      if (res.statusCode == 201) {
        await fetchUnits();
        Get.snackbar('Sukses', 'Unit ditambahkan');
        return json.decode(res.body)['data']['id'];
      }
      Get.snackbar('Error', 'Gagal tambah unit');
    } catch (e) {
      Get.snackbar('Error', 'Terjadi kesalahan');
    }
    return null;
  }

  Future<void> deleteUnit(String id) async {
    try {
      final res = await ProductService.deleteUnit(id);
      if (res.statusCode == 200) {
        Get.snackbar('Sukses', 'Unit berhasil dihapus');
        await fetchUnits();
      } else {
        Get.snackbar('Gagal', _parseErrorMessage(res.body));
      }
    } catch (e) {
      Get.snackbar('Error', 'Terjadi kesalahan');
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
    if (unitList.isNotEmpty) return unitList.first.id;
    return '';
  }

  String _parseErrorMessage(String body) {
    try {
      return json.decode(body)['message'] ?? 'Terjadi kesalahan';
    } catch (_) {
      return 'Terjadi kesalahan';
    }
  }
}
