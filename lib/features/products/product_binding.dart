import 'package:get/get.dart';
import 'package:senkukoadmin/features/products/controllers/product_controller.dart';
import 'package:senkukoadmin/features/products/controllers/product_image_controller.dart';
import 'package:senkukoadmin/features/products/controllers/product_variant_controller.dart';

class ProductBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<ProductImageController>(ProductImageController());
    Get.put<ProductVariantController>(ProductVariantController());
    Get.put<ProductController>(ProductController());
  }
}