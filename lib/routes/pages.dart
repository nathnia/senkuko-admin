import 'package:get/get.dart';
import 'package:senkukoadmin/features/admin/pages/add_voucher_page.dart';
import 'package:senkukoadmin/features/admin/pages/dashboard_page.dart';
import 'package:senkukoadmin/features/customers/customer_binding.dart';
import 'package:senkukoadmin/features/customers/customer_page.dart';
import 'package:senkukoadmin/features/products/pages/add_product_page.dart';
import 'package:senkukoadmin/features/products/pages/detail_product_page.dart';
import 'package:senkukoadmin/features/products/pages/edit_product_page.dart';
import 'package:senkukoadmin/features/products/pages/edit_variant_page.dart';
import 'package:senkukoadmin/features/products/product_binding.dart';
import 'package:senkukoadmin/features/products/pages/product_page.dart';
import 'package:senkukoadmin/features/promotions/condition_sheet.dart';
import 'package:senkukoadmin/features/promotions/promotion_detail_page.dart';
import 'package:senkukoadmin/features/promotions/promotion_form.dart';
import 'package:senkukoadmin/features/promotions/promotion_page.dart';
import 'package:senkukoadmin/features/promotions/promotion_binding.dart';
import 'package:senkukoadmin/features/promotions/promotion_reward_form.dart';
import 'package:senkukoadmin/features/promotions/voucher_binding.dart';
import 'package:senkukoadmin/features/promotions/voucher_form_page.dart';
import 'package:senkukoadmin/features/promotions/voucher_page.dart';
import 'package:senkukoadmin/features/transactions/transaction_binding.dart';
import 'package:senkukoadmin/features/transactions/transaction_detail_page.dart';
import 'package:senkukoadmin/features/transactions/transaction_page.dart';
import 'package:senkukoadmin/routes/routes.dart';
import 'package:senkukoadmin/features/auth/splash_page.dart';

// app_pages.dart
class AppPages {
  static final pages = [
    GetPage(name: AppRoutes.splash, page: () => SplashPage()),
    GetPage(name: AppRoutes.dashboard, page: () => DashboardPage()),
    GetPage(
      name: AppRoutes.product,
      page: () => ProductPage(),
      binding: ProductBinding(),
    ),
    GetPage(name: AppRoutes.addProduct, page: () => AddProductPage()),
    GetPage(name: AppRoutes.editProduct, page: () => EditProductPage()),
    GetPage(name: AppRoutes.editProductVariant, page: () => EditVariantPage()),
    GetPage(
      name: AppRoutes.detailProduct,
      page: () => DetailProductPage(),
      // ← hapus binding
    ),
    GetPage(
      name: AppRoutes.customer,
      page: () => CustomerPage(),
      binding: CustomerBinding(), 
    ),
    GetPage(
      name: AppRoutes.transaction,
      page: () => TransactionPage(),
      binding: TransactionBinding(), 
    ),
    GetPage(
      name: AppRoutes.transactionDetail,
      page: () => TransactionDetailPage(),
    ),
    GetPage(
      name: AppRoutes.promotions,
      page: () => PromotionPage(),
      binding: PromotionBinding(), 
    ),
    GetPage(
      name: AppRoutes.promotionDetail,
      page: () =>  PromotionDetailPage(),
    ),
    GetPage(
      name: AppRoutes.promotionForm,
      page: () =>  PromotionFormPage(),
    ),
    GetPage(
      name: AppRoutes.promotionConditionForm,
      page: () =>  PromotionConditionFormPage(),
    ),
    GetPage(
      name: AppRoutes.promotionRewardForm,
      page: () =>  PromotionRewardFormPage(),
    ),
    GetPage(name: AppRoutes.addPromo, page: () => PromotionFormPage()),
    GetPage(name: AppRoutes.addVoucher, page: () => AddVoucherPage()),
    GetPage(
  name: AppRoutes.vouchers,
  page: () => VoucherPage(),
  binding: VoucherBinding(),
),
GetPage(
  name: AppRoutes.voucherForm,
  page: () =>  VoucherFormPage(),
  binding: VoucherBinding(),
),
  ];
}
