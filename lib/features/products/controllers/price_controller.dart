import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:senkukoadmin/constant/cache_service.dart';
import 'package:senkukoadmin/constant/currency_formatter.dart';
import 'package:senkukoadmin/features/products/controllers/product_controller.dart';
import 'package:senkukoadmin/features/products/controllers/product_variant_controller.dart';
import 'package:senkukoadmin/features/products/models/product_price_model.dart';
import 'package:senkukoadmin/features/products/models/product_pricelist_model.dart';
import 'package:senkukoadmin/features/products/product_service.dart';

class PriceController extends GetxController {
  final priceList = <PriceData>[].obs;
  final priceListMaster = <PricelistData>[].obs;

  // ── Form prices (add variant)
  final formPrices = <String, Map<String, dynamic>>{}.obs;
  final Map<String, TextEditingController> priceControllers = {};

  // ── Dialog prices (edit variant)
  final dialogPrices = <String, Map<String, dynamic>>{}.obs;
  final Map<String, TextEditingController> dialogPriceC = {};

  @override
  void onClose() {
    for (var c in [...priceControllers.values, ...dialogPriceC.values]) {
      c.dispose();
    }
    super.onClose();
  }

  // ===================== FETCH =====================
  // CHANGED: downgrade dari Pola B ke Pola A — skip network sepenuhnya
  // kalau masih dalam TTL. Harga berubah lewat aksi admin (form edit),
  // bukan efek samping otomatis dari transaksi kayak stok, jadi lebih
  // mirip Product/Category ketimbang allVariants. Pakai CacheKeys.priceTtl
  // (dipisah dari stockPriceTtl yang tetap dipakai allVariants/Pola B)
  // biar TTL-nya gak ke-couple sama data stok yang beda karakteristik.
  Future<void> fetchPrices({bool forceRefresh = false}) async {
    void notifySummaryCache() {
      if (Get.isRegistered<ProductVariantController>()) {
        Get.find<ProductVariantController>().invalidateSummaryCache();
      }
    }

    if (!forceRefresh) {
      final cached = CacheService.instance.get(
        CacheKeys.priceList,
        ttl: CacheKeys.priceTtl,
      );
      if (cached != null) {
        // FIX: paksa jalur cache-hit gak pernah 100% sinkron — nyegah
        // crash build-phase kalau dipanggil dari initState() page.
        await Future.microtask(() {});
        priceList.assignAll(
          (cached as List).map((e) => PriceData.fromJson(e)).toList(),
        );
        notifySummaryCache();
        return; // cache masih valid, skip network sepenuhnya
      }
    }

    final res = await ProductService.getPrices();
    if (res.statusCode == 200) {
      final list = productPriceModelFromJson(res.body).data;
      priceList.assignAll(list);
      await CacheService.instance.set(
        CacheKeys.priceList,
        list.map((p) => p.toJson()).toList(),
      );
      // FIX: priceList adalah salah satu sumber data ProductSummary
      // (lihat ProductVariantController._computeSummary). Sebelumnya
      // cuma fetchAllVariants() yang invalidate summary cache, jadi
      // kalau fetchPrices() selesai belakangan (race di Future.wait
      // pas loadInitialData), harga produk ke-cache 0 secara permanen
      // sampai ada trigger invalidate lain (mis. pull-to-refresh).
      notifySummaryCache();
    }
  }

  Future<void> fetchPriceLists({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cached = CacheService.instance.get(
        CacheKeys.priceListMaster,
        ttl: CacheKeys.referenceDataTtl,
      );
      if (cached != null) {
        // FIX: paksa jalur cache-hit gak pernah 100% sinkron — nyegah
        // crash build-phase kalau dipanggil dari initState() page.
        await Future.microtask(() {});
        priceListMaster.assignAll(
          (cached as List).map((e) => PricelistData.fromJson(e)).toList(),
        );
        return;
      }
    }

    final res = await ProductService.getPriceLists();
    if (res.statusCode == 200) {
      final list = priceListModelFromJson(res.body).data;
      priceListMaster.assignAll(list);
      await CacheService.instance.set(
        CacheKeys.priceListMaster,
        list.map((p) => p.toJson()).toList(),
      );
    }
  }

  // ===================== INIT CONTROLLERS =====================
  void initPriceControllers() {
    // Guard: jangan init kalau master belum terisi
    if (priceListMaster.isEmpty) return;

    for (var p in priceListMaster) {
      priceControllers.putIfAbsent(p.id, () => TextEditingController());
      formPrices.putIfAbsent(p.id, () => {'enabled': false});
    }
  }

  void initDialogPrices({
    required List priceListMasterList,
    required List? existingPrices,
  }) {
    for (var c in dialogPriceC.values) {
      c.dispose();
    }
    dialogPriceC.clear();
    dialogPrices.clear();

    for (var pl in priceListMasterList) {
      final existing = existingPrices?.firstWhereOrNull(
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

  void clearFormPrices({ProductController? productC}) {
    for (var c in priceControllers.values) {
      c.clear();
    }
    for (var id in formPrices.keys) {
      formPrices[id] = {'enabled': false};
    }
    formPrices.refresh();
    productC?.checkDirty();
  }

  void togglePrice(
    String priceListId, {
    bool isDialog = false,
    ProductController? productC,
  }) {
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

    // Dialog mode: set isDirty langsung ke ProductController
    // Non-dialog: dirty check ditangani ProductVariantController.checkVariantDirty()
    if (isDialog) productC?.isDirty.value = true;
  }

  // ===================== PRICE DISPLAY HELPERS =====================
  List<PriceData> getPricesByVariant(String variantId) =>
      priceList.where((e) => e.productVariantId == variantId).toList();

  // ===================== PRICE LIST SORTED =====================
  List<PricelistData> get sortedPriceListMaster {
    return [...priceListMaster]..sort((a, b) {
      final aCode = a.code.toLowerCase();
      final bCode = b.code.toLowerCase();
      if (aCode == 'normal') return -1;
      if (bCode == 'normal') return 1;
      if (aCode == 'member') return -1;
      if (bCode == 'member') return 1;
      return 0;
    });
  }

  List<Map<String, dynamic>> sortPricesByMaster(List prices) {
    final sortedOrder = sortedPriceListMaster.map((pl) => pl.id).toList();
    return [...prices]..sort((a, b) {
      final ai = sortedOrder.indexOf(a['price_list_id']?.toString() ?? '');
      final bi = sortedOrder.indexOf(b['price_list_id']?.toString() ?? '');
      return (ai == -1 ? sortedOrder.length : ai).compareTo(
        bi == -1 ? sortedOrder.length : bi,
      );
    });
  }

  // ===================== PRICE SYNC =====================

  // Ambil harga terkini dari backend untuk satu variant
  Future<List<Map<String, dynamic>>> loadPricesForVariant(
    String variantId,
  ) async {
    try {
      final res = await ProductService.getPricesByVariant(variantId);
      if (res.statusCode != 200) return [];

      final jsonData = json.decode(res.body);

      final List rawList = (jsonData['data']?['prices'] as List? ?? []);

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

  // Sync harga: create / update / delete secara parallel
  Future<void> syncPrices({
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

    // Klasifikasi operasi
    final toCreate = <Map<String, dynamic>>[];
    final toUpdate = <Map<String, dynamic>>[];
    final toDelete = <Map<String, dynamic>>[];

    for (var np in newPrices) {
      final plId = np['price_list_id']?.toString() ?? '';
      final newValue = double.tryParse(np['price']?.toString() ?? '0') ?? 0;
      if (plId.isEmpty || newValue <= 0) continue;

      if (existingMap.containsKey(plId)) {
        final existing = existingMap[plId]!;
        final existingId = existing['id']?.toString() ?? '';
        final oldValue =
            double.tryParse(existing['price']?.toString() ?? '0') ?? 0;
        // Hanya update kalau nilainya berubah
        if (existingId.isNotEmpty && oldValue != newValue) {
          toUpdate.add({
            'id': existingId,
            'price_list_id': plId,
            'price': newValue,
          });
        }
      } else {
        toCreate.add({'price_list_id': plId, 'price': newValue});
      }
    }

    for (var ep in existingPrices) {
      final plId = ep['price_list_id']?.toString() ?? '';
      final priceId = ep['id']?.toString() ?? '';
      if (!newPriceListIds.contains(plId) && priceId.isNotEmpty) {
        toDelete.add(ep);
      }
    }

    // Semua operasi jalan parallel — dari ~800ms jadi ~200ms
    await Future.wait([
      ...toCreate.map(
        (p) => ProductService.createPrice(
          variantId: variantId,
          priceListId: p['price_list_id'],
          price: (p['price'] as num).toDouble(),
        ),
      ),
      ...toUpdate.map(
        (p) => ProductService.updatePrice(
          priceId: p['id'],
          priceListId: p['price_list_id'],
          price: (p['price'] as num).toDouble(),
        ),
      ),
      ...toDelete.map((p) => ProductService.deletePrice(p['id'])),
    ]);
  }
}