import 'package:get/get.dart';
import 'package:senkukoadmin/features/products/product_controller.dart';

class ProductBinding extends Bindings{
  @override
  void dependencies() {
    Get.lazyPut<ProductController>(()=>ProductController());
  }
}