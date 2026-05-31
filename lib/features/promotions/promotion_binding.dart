import 'package:get/get.dart';
import 'package:senkukoadmin/features/products/controllers/category_controller.dart';
import 'package:senkukoadmin/features/products/controllers/product_controller.dart';
import 'package:senkukoadmin/features/products/controllers/product_variant_controller.dart';
import 'package:senkukoadmin/features/promotions/promotion_controller.dart';
import 'package:senkukoadmin/features/vouchers/voucher_controller.dart';

class PromotionBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PromotionController>(() => PromotionController(), fenix: true);
    Get.lazyPut<VoucherController>(() => VoucherController(), fenix: true);
    Get.lazyPut(() => ProductVariantController(), fenix: true);
    Get.lazyPut(() => CategoryController(), fenix: true);
    Get.lazyPut(() => ProductController(), fenix: true);
  }
}
