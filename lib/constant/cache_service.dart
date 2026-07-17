// FILE: lib/constant/cache_service.dart

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Generic TTL-based cache di atas shared_preferences.
///
/// PRINSIP PENTING: awalnya service ini cuma buat REFERENCE DATA
/// (categories, units, price list master) dan PRODUCT LIST METADATA.
/// Sekarang juga dipakai buat allVariants & priceList — TAPI dengan TTL
/// pendek (CacheKeys.stockPriceTtl) dan selalu dipasangkan sama live
/// background refetch + manual invalidation di controller masing-masing
/// (lihat product_variant_controller & price_controller). Cache di sini
/// buat data stok/harga cuma berfungsi sebagai "instant paint" pas buka
/// halaman, BUKAN sumber kebenaran — network tetap selalu dipanggil.
class CacheService {
  CacheService._();
  static final CacheService instance = CacheService._();

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  static const _tsPrefix = 'cache_ts_';
  static const _dataPrefix = 'cache_data_';

  /// Simpan data (harus JSON-encodable: Map/List/primitive) + timestamp now.
  Future<void> set(String key, dynamic jsonEncodableData) async {
    await init();
    final p = _prefs!;
    await p.setString('$_dataPrefix$key', json.encode(jsonEncodableData));
    await p.setInt('$_tsPrefix$key', DateTime.now().millisecondsSinceEpoch);
  }

  /// Ambil data kalau masih dalam TTL. Return null kalau miss/expired/belum init.
  /// Sengaja SYNC (bukan Future) supaya bisa dipanggil langsung di awal
  /// fetch tanpa nunggu — kalau belum di-init, dianggap cache miss (aman,
  /// cuma fallback ke network seperti biasa).
  dynamic get(String key, {required Duration ttl}) {
    final p = _prefs;
    if (p == null) return null;

    final ts = p.getInt('$_tsPrefix$key');
    final raw = p.getString('$_dataPrefix$key');
    if (ts == null || raw == null) return null;

    final age = DateTime.now().millisecondsSinceEpoch - ts;
    if (age > ttl.inMilliseconds) return null;

    try {
      return json.decode(raw);
    } catch (_) {
      return null;
    }
  }

  Future<void> invalidate(String key) async {
    await init();
    final p = _prefs!;
    await p.remove('$_dataPrefix$key');
    await p.remove('$_tsPrefix$key');
  }

  Future<void> invalidateAll(Iterable<String> keys) async {
    for (final k in keys) {
      await invalidate(k);
    }
  }
}

/// Key & TTL terpusat — biar konsisten di semua controller, gak ada
/// typo-key atau TTL yang beda-beda tanpa sengaja.
class CacheKeys {
  CacheKeys._();

  static const categories = 'categories';
  static const units = 'units';
  static const priceListMaster = 'price_list_master';
  static const productList = 'product_list';

  // ADDED: cache buat data stok (allVariants) & harga (priceList).
  // Dipakai dengan pola cache-first + background refresh (Pola B) di
  // ProductVariantController.fetchAllVariants() & PriceController.fetchPrices()
  static const allVariants = 'all_variants';
  static const priceList = 'price_list';

  static const referenceDataTtl = Duration(hours: 1);
  static const productListTtl = Duration(minutes: 5);

  // ADDED: TTL sengaja jauh lebih pendek dari data lain — allVariants
  // (stok) & priceList (harga) bisa berubah kapan aja (ada transaksi
  // masuk, harga diubah admin lain, dll). TTL ini cuma buat nge-cover
  // jeda "instant paint" pas buka halaman, bukan buat nunda network call.
  static const stockPriceTtl = Duration(seconds: 30);
}