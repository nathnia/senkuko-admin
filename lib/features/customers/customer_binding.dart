import 'package:get/get.dart';
import 'package:senkukoadmin/features/customers/customer_controller.dart';

class CustomerBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<CustomerController>()) {
      Get.put<CustomerController>(CustomerController(), permanent: true);
    }
  }
}