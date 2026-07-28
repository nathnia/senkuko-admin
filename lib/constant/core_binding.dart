// FILE: lib/core_binding.dart

import 'package:get/get.dart';
import 'package:senkukoadmin/features/products/controllers/category_controller.dart';
import 'package:senkukoadmin/features/products/controllers/import_controller.dart';
import 'package:senkukoadmin/features/products/controllers/price_controller.dart';
import 'package:senkukoadmin/features/products/controllers/product_controller.dart';
import 'package:senkukoadmin/features/products/controllers/product_image_controller.dart';
import 'package:senkukoadmin/features/products/controllers/product_variant_controller.dart';
import 'package:senkukoadmin/features/products/controllers/unit_controller.dart';
import 'package:senkukoadmin/features/promotions/promotion_controller.dart';
import 'package:senkukoadmin/features/vouchers/voucher_controller.dart';
import 'package:senkukoadmin/features/transactions/transaction_controller.dart';

/// ─────────────────────────────────────────────────────────────────────────
/// SATU-SATUNYA tempat yang mendaftarkan controller yang dipakai LINTAS
/// fitur (Product, Category, Unit, Price, Promotion, Voucher, Customer,
/// Transaction). Dipasang sekali lewat `initialBinding` di GetMaterialApp
/// (lihat main.dart) — SELALU jalan duluan sebelum binding halaman manapun.
///
/// KENAPA INI PERLU:
/// Sebelumnya, controller yang sama (mis. ProductController) didaftarkan
/// di beberapa binding berbeda (ProductBinding, DashboardBinding,
/// PromotionBinding) dengan setting lifecycle yang beda-beda (permanent
/// vs fenix). Karena Get.isRegistered cuma cek "sudah ada belum" — bukan
/// "settingnya benar belum" — binding mana yang kepanggil DULUAN yang
/// menentukan lifecycle final controller itu. Ini bikin behaviour app
/// jadi tergantung urutan halaman yang dibuka user, yang gak reliable.
///
/// ATURAN:
/// - Controller app-wide/lintas-fitur → didaftarkan DI SINI SAJA.
/// - Binding per-fitur (ProductBinding, dst) TIDAK BOLEH lagi
///   mendaftarkan controller-controller ini.
/// - Controller yang BENERAN spesifik satu fitur (gak dipakai fitur lain)
///   tetap boleh didaftarkan di binding fitur masing-masing seperti biasa.
/// ─────────────────────────────────────────────────────────────────────────
class CoreBinding extends Bindings {
  @override
  void dependencies() {
    _putPermanent(() => ProductImageController());
    _putPermanent(() => ProductVariantController());
    _putPermanent(() => CategoryController());
    _putPermanent(() => UnitController());
    _putPermanent(() => PriceController());
    _putPermanent(() => ProductController());
    _putPermanent(() => PromotionController());
    _putPermanent(() => VoucherController());
    _putPermanent(() => TransactionController());

    // ImportController jarang dipakai & cukup berat (isolate parsing utk
    // Excel bulk import) — gak perlu permanent, fenix cukup biar bisa
    // di-dispose kalau lagi gak dipakai.
    Get.lazyPut(() => ImportController(), fenix: true);
  }

  void _putPermanent<T>(T Function() builder) {
    if (!Get.isRegistered<T>()) {
      Get.put<T>(builder(), permanent: true);
    }
  }
}