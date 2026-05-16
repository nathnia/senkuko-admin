import 'package:get/get.dart';
import 'package:senkukoadmin/features/promotions/promotion_controller.dart';

class PromotionBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PromotionController>(() => PromotionController(), fenix: true);
  }
}
