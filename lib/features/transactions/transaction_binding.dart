import 'package:get/get.dart';
import 'package:senkukoadmin/features/transactions/transaction_controller.dart';

class TransactionBinding extends Bindings {
  @override
  void dependencies() {
    // Kalau controller sudah ada (dari DashboardBinding), tidak perlu buat baru.
    // Kalau belum ada, buat baru.
    if (!Get.isRegistered<TransactionController>()) {
      Get.put<TransactionController>(TransactionController());
    }
  }
}