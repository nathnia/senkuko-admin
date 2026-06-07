import 'package:get/get.dart';
import 'package:senkukoadmin/features/products/controllers/category_controller.dart';
import 'package:senkukoadmin/features/products/controllers/price_controller.dart';
import 'package:senkukoadmin/features/products/controllers/product_controller.dart';
import 'package:senkukoadmin/features/products/controllers/product_image_controller.dart';
import 'package:senkukoadmin/features/products/controllers/product_variant_controller.dart';
import 'package:senkukoadmin/features/products/controllers/unit_controller.dart';
import 'package:senkukoadmin/features/transactions/transaction_controller.dart';

class DashboardBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<TransactionController>(
      () => TransactionController(),
      fenix: true,
    );
        Get.lazyPut(() => ProductImageController(), fenix: true);
    Get.lazyPut(() => ProductVariantController(), fenix: true);
    Get.lazyPut(() => UnitController(), fenix: true);
    Get.lazyPut(() => PriceController(), fenix: true);
    Get.lazyPut(() => CategoryController(), fenix: true);
    Get.lazyPut(() => ProductController(), fenix: true);

  }
}