import 'package:get/get.dart';
import 'package:senkukoadmin/features/admin/pages/add_promo_page.dart';
import 'package:senkukoadmin/features/admin/pages/add_voucher_page.dart';
import 'package:senkukoadmin/features/admin/pages/dashboard_page.dart';
import 'package:senkukoadmin/features/admin/pages/promo_page.dart';
import 'package:senkukoadmin/features/admin/pages/voucher_page.dart';
import 'package:senkukoadmin/features/customers/add_customer_page.dart';
import 'package:senkukoadmin/features/customers/customer_binding.dart';
import 'package:senkukoadmin/features/customers/customer_page.dart';
import 'package:senkukoadmin/features/products/pages/add_product_page.dart';
import 'package:senkukoadmin/features/products/pages/detail_product_page.dart';
import 'package:senkukoadmin/features/products/pages/edit_product_page.dart';
import 'package:senkukoadmin/features/products/product_binding.dart';
import 'package:senkukoadmin/features/products/pages/product_page.dart';
import 'package:senkukoadmin/features/transactions/transaction_binding.dart';
import 'package:senkukoadmin/features/transactions/transaction_detail_page.dart';
import 'package:senkukoadmin/features/transactions/transaction_page.dart';
import 'package:senkukoadmin/routes/routes.dart';
import 'package:senkukoadmin/features/auth/splash_page.dart';

// app_pages.dart
class AppPages {
  static final pages = [
    GetPage(name: AppRoutes.splash, page: () => SplashPage()),
    GetPage(
      name: AppRoutes.dashboard,
      page: () => DashboardPage(),
      binding: ProductBinding(), // ← tetap di sini buat preload
    ),
    GetPage(
      name: AppRoutes.product,
      page: () => ProductPage(),
      // ← hapus binding, udah di-register di dashboard
    ),
    GetPage(
      name: AppRoutes.addProduct,
      page: () => AddProductPage(),
      // ← hapus binding
    ),
    GetPage(
      name: AppRoutes.editProduct,
      page: () => EditProductPage(),
      // ← hapus binding
    ),
    GetPage(
      name: AppRoutes.detailProduct,
      page: () => DetailProductPage(),
      // ← hapus binding
    ),
    GetPage(
      name: AppRoutes.customer,
      page: () => CustomerPage(),
      binding: CustomerBinding(), // ← register sekali di sini
    ),
    GetPage(
      name: AppRoutes.customerForm,
      page: () => AddCustomerPage(),
      binding: CustomerBinding(), // ← tambah ini
    ),
    GetPage(
      name: AppRoutes.transaction,
      page: () => TransactionPage(),
      binding: TransactionBinding(), // ← tambah ini
    ),
    GetPage(
      name: AppRoutes.transactionDetail,
      page: () => TransactionDetailPage(),
    ),
    GetPage(name: AppRoutes.promo, page: () => PromoPage()),
    GetPage(name: AppRoutes.voucher, page: () => VoucherPage()),
    GetPage(name: AppRoutes.addPromo, page: () => AddPromoPage()),
    GetPage(name: AppRoutes.addVoucher, page: () => AddVoucherPage()),
  ];
}
