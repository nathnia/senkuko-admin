// FILE: lib/constant/cache_service.dart

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Generic TTL-based cache di atas shared_preferences.
///
/// PRINSIP PENTING: awalnya service ini cuma buat REFERENCE DATA
/// (categories, units, price list master) dan PRODUCT LIST METADATA.
/// Sekarang juga dipakai buat allVariants & priceList — TAPI dengan
/// pola yang beda:
/// - allVariants (stok) tetap Pola B: TTL pendek (CacheKeys.stockPriceTtl),
///   selalu dipasangkan sama live background refetch. Cache di sini cuma
///   berfungsi sebagai "instant paint" pas buka halaman, BUKAN sumber
///   kebenaran — network SELALU dipanggil apa pun TTL-nya. Sengaja gak
///   dinaikin TTL-nya biar gampang dibedain intent-nya dari priceList.
/// - priceList (harga) sekarang Pola A: TTL lebih panjang
///   (CacheKeys.priceTtl), skip network SEPENUHNYA kalau masih fresh —
///   sama kelasnya kayak productList/categories (harga cuma berubah
///   lewat aksi admin, bukan efek otomatis dari transaksi kayak stok).
///
/// ADDED: `banners` — Banner masuk kategori REFERENCE DATA juga (jarang
/// berubah, gak kritis kalau agak basi, ada pull-to-refresh sebagai
/// manual override), jadi dikasih TTL panjang (referenceDataTtl) sama
/// kayak categories/units — BUKAN pola instant-paint kayak allVariants.
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

  // ADDED: banner — reference data, TTL panjang sama kayak categories/units.
  static const banners = 'banners';

  // ADDED: cache buat data stok (allVariants) & harga (priceList).
  static const allVariants = 'all_variants';
  static const priceList = 'price_list';

  static const referenceDataTtl = Duration(hours: 1);
  static const productListTtl = Duration(minutes: 5);

  // allVariants (stok) — TETAP pendek & TETAP Pola B (selalu network-
  // refresh apa pun hasil cache-nya). TTL ini CUMA ngatur seberapa lama
  // cache lama masih dianggap layak dipakai buat instant-paint pas
  // nunggu network — BUKAN keputusan skip-network. Jangan disamain sama
  // priceTtl di bawah, dan jangan dinaikin buat "ngirit" — stok gak
  // boleh punya window skip-network sama sekali (dipakai juga buat cek
  // stok sebelum "Proses Pesanan").
  static const stockPriceTtl = Duration(seconds: 30);

  // CHANGED: dipisah dari stockPriceTtl karena priceList sekarang Pola A
  // (skip network sepenuhnya kalau masih dalam TTL ini) — beda pola sama
  // allVariants yang tetap Pola B. Disamain kelasnya sama productListTtl
  // karena sama-sama "cuma berubah lewat aksi admin".
  static const priceTtl = Duration(minutes: 5);
}