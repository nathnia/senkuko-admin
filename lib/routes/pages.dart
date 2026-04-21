import 'package:get/get.dart';
import 'package:senkukoadmin/features/admin/pages/add_promo_page.dart';
import 'package:senkukoadmin/features/admin/pages/add_voucher_page.dart';
import 'package:senkukoadmin/features/admin/pages/dashboard_page.dart';
import 'package:senkukoadmin/features/admin/pages/order_detail_page.dart';
import 'package:senkukoadmin/features/admin/pages/order_page.dart';
import 'package:senkukoadmin/features/admin/pages/promo_page.dart';
import 'package:senkukoadmin/features/admin/pages/voucher_page.dart';
import 'package:senkukoadmin/features/products/pages/add_product_page.dart';
import 'package:senkukoadmin/features/products/pages/detail_product_page.dart';
import 'package:senkukoadmin/features/products/pages/edit_product_page.dart';
import 'package:senkukoadmin/features/products/product_binding.dart';
import 'package:senkukoadmin/features/products/pages/product_page.dart';
import 'package:senkukoadmin/routes/routes.dart';
import 'package:senkukoadmin/features/auth/splash_page.dart';

class AppPages {
  static final pages = [
    GetPage(name: AppRoutes.splash, page: () => SplashPage()),
    GetPage(name: AppRoutes.dashboard, page: () => DashboardPage()),
    GetPage(name: AppRoutes.order, page: () => OrderPage()),
    GetPage(name: AppRoutes.detailOrder, page: () => OrderDetailPage()),
    GetPage(
      name: AppRoutes.product,
      page: () => ProductPage(),
      binding: ProductBinding(),
    ),
    GetPage(
      name: AppRoutes.addProduct,
      page: () => AddProductPage(),
      binding: ProductBinding(),
    ),
    GetPage(
      name: AppRoutes.editProduct,
      page: () => EditProductPage(),
      binding: ProductBinding(),
    ),
    GetPage(
      name: AppRoutes.detailProduct,
      page: () => DetailProductPage(),
      binding: ProductBinding(),

    ),
    GetPage(name: AppRoutes.promo, page: () => PromoPage()),
    GetPage(name: AppRoutes.voucher, page: () => VoucherPage()),
    GetPage(name: AppRoutes.addPromo, page: () => AddPromoPage()),
    GetPage(name: AppRoutes.addVoucher, page: () => AddVoucherPage()),
  ];
}
