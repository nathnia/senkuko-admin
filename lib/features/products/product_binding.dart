import 'package:get/get.dart';
import 'package:senkukoadmin/features/products/controllers/product_controller.dart';
import 'package:senkukoadmin/features/products/controllers/product_image_controller.dart';
import 'package:senkukoadmin/features/products/controllers/product_variant_controller.dart';

// features/products/product_binding.dart
class ProductBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => ProductImageController());
    Get.lazyPut(() => ProductVariantController());
    Get.lazyPut(() => ProductController());
  }
}
