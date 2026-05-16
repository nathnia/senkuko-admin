import 'package:flutter/material.dart';
import 'package:get/get_navigation/get_navigation.dart';
import 'package:senkukoadmin/constant/app_colors.dart';
import 'package:senkukoadmin/routes/pages.dart';
import 'package:senkukoadmin/routes/routes.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID'); // ← wajib sebelum runApp
  runApp(const MyApp());
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
      initialRoute: AppRoutes.dashboard,
      getPages: AppPages.pages,
    );
  }
}