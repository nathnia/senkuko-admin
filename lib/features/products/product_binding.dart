// FILE: lib/features/products/product_binding.dart

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
   
    _putPermanent(() => ProductImageController());
    _putPermanent(() => ProductVariantController());
    _putPermanent(() => UnitController());
    _putPermanent(() => PriceController());
    _putPermanent(() => CategoryController());
    _putPermanent(() => ProductController());

    Get.lazyPut(() => ImportController(), fenix: true);
  }

  void _putPermanent<T>(T Function() builder) {
    if (!Get.isRegistered<T>()) {
      Get.put<T>(builder(), permanent: true);
    }
  }
}