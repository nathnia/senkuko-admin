import 'package:get/get.dart';
import 'package:senkukoadmin/features/auth/auth_binding.dart';
import 'package:senkukoadmin/features/auth/login_page.dart';
import 'package:senkukoadmin/features/auth/splash_page.dart';
import 'package:senkukoadmin/features/customers/customer_form.dart';
import 'package:senkukoadmin/features/dashboard_page.dart';
import 'package:senkukoadmin/features/customers/customer_page.dart';
import 'package:senkukoadmin/features/products/pages/add_product_page.dart';
import 'package:senkukoadmin/features/products/pages/detail_product_page.dart';
import 'package:senkukoadmin/features/products/pages/edit_product_page.dart';
import 'package:senkukoadmin/features/products/pages/import_product_page.dart';
import 'package:senkukoadmin/features/products/pages/manage_categories_page.dart';
import 'package:senkukoadmin/features/products/pages/variant_form_page.dart';
import 'package:senkukoadmin/features/products/pages/product_page.dart';
import 'package:senkukoadmin/features/promotions/condition_sheet.dart';
import 'package:senkukoadmin/features/promotions/promotion_detail_page.dart';
import 'package:senkukoadmin/features/promotions/promotion_form.dart';
import 'package:senkukoadmin/features/promotions/promotion_page.dart';
import 'package:senkukoadmin/features/promotions/promotion_reward_form.dart';
import 'package:senkukoadmin/features/vouchers/voucher_form_page.dart';
import 'package:senkukoadmin/features/vouchers/voucher_page.dart';
import 'package:senkukoadmin/features/transactions/transaction_detail_page.dart';
import 'package:senkukoadmin/features/transactions/transaction_page.dart';
import 'package:senkukoadmin/routes/routes.dart';


class AppPages {
  static final pages = [
    GetPage(
      name: AppRoutes.splash,
      page: () => const SplashPage(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginPage(),
      binding: AuthBinding(),
    ),
    GetPage(name: AppRoutes.dashboard, page: () => DashboardPage()),
    GetPage(
      name: AppRoutes.product,
      page: () => ProductPage(),
    ),
    GetPage(name: AppRoutes.addProduct, page: () => AddProductPage()),
    GetPage(name: AppRoutes.editProduct, page: () => EditProductPage()),
    GetPage(name: AppRoutes.detailProduct, page: () => DetailProductPage()),
    GetPage(
      name: AppRoutes.importProduct,
      page: () => const ImportProductPage(),
    ),
    GetPage(
      name: AppRoutes.customer,
      page: () => const CustomerPage(),
    ),
    GetPage(
      name: AppRoutes.customerForm,
      page: () => const CustomerFormPage(),
    ),
    GetPage(
      name: AppRoutes.transaction,
      page: () => TransactionPage(),
    ),
    GetPage(
      name: AppRoutes.transactionDetail,
      page: () => TransactionDetailPage(),
    ),
    GetPage(
      name: AppRoutes.promotions,
      page: () => PromotionPage(),
    ),
    GetPage(name: AppRoutes.promotionDetail, page: () => PromotionDetailPage()),
    GetPage(name: AppRoutes.promotionForm, page: () => PromotionFormPage()),
    GetPage(
      name: AppRoutes.promotionConditionForm,
      page: () => PromotionConditionFormPage(),
    ),
    GetPage(
      name: AppRoutes.promotionRewardForm,
      page: () => PromotionRewardFormPage(),
    ),
    GetPage(name: AppRoutes.addPromo, page: () => PromotionFormPage()),
    GetPage(
      name: AppRoutes.vouchers,
      page: () => VoucherPage(),
    ),
    GetPage(
      name: AppRoutes.voucherForm,
      page: () => VoucherFormPage(),
    ),
    GetPage(name: AppRoutes.variantForm, page: () => VariantFormPage()),
    GetPage(
      name: AppRoutes.manageCategories,
      page: () => ManageCategoriesPage(),
    ),
  ];
}