import 'package:get/get.dart';
import 'package:senkukoadmin/features/auth/auth_controller.dart';

class AuthBinding extends Bindings {
  @override
  void dependencies() {
    /// fenix: true supaya controller tidak di-dispose saat navigasi,
    /// penting karena AuthController menyimpan session global.
    Get.lazyPut<AuthController>(
      () => AuthController(),
      fenix: true,
    );
  }
}