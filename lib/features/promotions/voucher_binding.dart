import 'package:get/get.dart';
import 'package:senkukoadmin/features/promotions/voucher_controller.dart';

class VoucherBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<VoucherController>(
      () => VoucherController(),
      fenix: true,
    );
  }
}