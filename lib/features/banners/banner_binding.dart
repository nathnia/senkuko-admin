// FILE: lib/features/banners/banner_binding.dart
import 'package:get/get.dart';
import 'package:senkukoadmin/features/banners/banner_controller.dart';

class BannerBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<BannerController>()) {
      Get.put(BannerController(), permanent: true);
    }
  }
}