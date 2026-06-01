// FILE: lib/features/products/product_binding.dart
//
// ExportController didaftarkan lazyPut terakhir — tidak ada dependency saat
// fitur export tidak dibuka. fenix: true agar tidak di-GC saat halaman pop.

import 'package:get/get.dart';
import 'package:senkukoadmin/features/products/controllers/category_controller.dart';
import 'package:senkukoadmin/features/products/controllers/import_controller.dart';
import 'package:senkukoadmin/features/products/controllers/price_controller.dart';
import 'package:senkukoadmin/features/products/controllers/product_controller.dart';
import 'package:senkukoadmin/features/products/controllers/product_image_controller.dart';
import 'package:senkukoadmin/features/products/controllers/product_variant_controller.dart';
import 'package:senkukoadmin/features/products/controllers/unit_controller.dart';

class ProductBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => ProductImageController(), fenix: true);
    Get.lazyPut(() => ProductVariantController(), fenix: true);
    Get.lazyPut(() => UnitController(), fenix: true);
    Get.lazyPut(() => PriceController(), fenix: true);
    Get.lazyPut(() => CategoryController(), fenix: true);
    Get.lazyPut(() => ProductController(), fenix: true);

    // Export: lazy, tidak ada overhead sampai user tap tombol export
    Get.lazyPut(() => ImportController(), fenix: true);
  }
}