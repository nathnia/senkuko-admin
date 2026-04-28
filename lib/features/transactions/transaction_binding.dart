import 'package:get/get.dart';
import 'package:senkukoadmin/features/transactions/transaction_controller.dart';

class TransactionBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<TransactionController>(
      () => TransactionController(),
      fenix: true,
    );
  }
}