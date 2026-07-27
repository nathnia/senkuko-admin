import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:senkukoadmin/constant/app_colors.dart';
import 'package:senkukoadmin/constant/cache_service.dart';
import 'package:senkukoadmin/constant/connectivity_banner.dart';
import 'package:senkukoadmin/constant/connectivity_service.dart';
import 'package:senkukoadmin/constant/core_binding.dart';
import 'package:senkukoadmin/features/auth/auth_controller.dart';
import 'package:senkukoadmin/routes/pages.dart';
import 'package:senkukoadmin/routes/routes.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  await runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    await dotenv.load(fileName: ".env"); 
    await GetStorage.init();
    await CacheService.instance.init();
    await initializeDateFormatting('id_ID');
    Get.put(ConnectivityService(), permanent: true);
    Get.put(AuthController(), permanent: true);
    runApp(const MyApp());
  }, (error, stack) {
    debugPrint('Startup error: $error');
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Senkuko',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
        useMaterial3: true,
      ),
      initialBinding: CoreBinding(),
      initialRoute: AppRoutes.splash,
      getPages: AppPages.pages,
      builder: (context, child) => Column(
        children: [
          Expanded(child: child ?? const SizedBox()),
          const ConnectivityBanner(),
        ],
      ),
    );
  }
}