import 'package:get/get.dart';
import 'package:senkukoadmin/features/customers/customer_controller.dart';

class CustomerBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CustomerController>(
      () => CustomerController(),
      fenix: true,
    );
  }
}