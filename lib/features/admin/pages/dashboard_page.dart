import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:senkukoadmin/constant/app_colors.dart';
import 'package:senkukoadmin/routes/routes.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  // Dummy data
  final int needsProcessing = 5;
  final int needsShipping = 3;
  final int cancellations = 1;
  final int totalProducts = 120;
  final int lowStock = 8;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        centerTitle: true,
        title: const Text(
          'Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            _orderCard(),
            const SizedBox(height: 8),
            _productCard(),
            const SizedBox(height: 8),
            _menuItem(Icons.grid_view_rounded, 'Kategori'),
            const SizedBox(height: 12),
            _menuItem(Icons.local_offer_rounded, 'Promo', onTap: () => Get.toNamed(AppRoutes.promo),),
            const SizedBox(height: 12),
            _menuItem(Icons.confirmation_number_rounded, 'Voucher', onTap: () => Get.toNamed(AppRoutes.voucher),),
            const SizedBox(height: 12),
            _menuItem(Icons.bar_chart_rounded, 'Performa'),
          ],
        ),
      ),
    );
  }

  // ================= ORDER =================
  Widget _orderCard() {
    return GestureDetector(
      onTap: () {
        Get.toNamed(AppRoutes.order);
      },
      child: _cardContainer(
        icon: Icons.shopping_cart,
        title: 'Pesanan',
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _statItem(needsProcessing, 'Perlu Diproses', AppColors.primary),
            _statItem(needsShipping, 'Perlu Dikirim', AppColors.primary),
            _statItem(cancellations, 'Pembatalan', AppColors.primary),
          ],
        ),
      ),
    );
  }

  // ================= PRODUCT =================
  Widget _productCard() {
    return GestureDetector(
      onTap: () {
        Get.toNamed(AppRoutes.product);
      },
      child: _cardContainer(
        icon: Icons.inventory_2,
        title: 'Produk',
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _statItem(totalProducts, 'Total Produk', AppColors.primary),
                _statItem(lowStock, 'Stok Menipis', AppColors.warning),
              ],
            ),
            const SizedBox(height: 20),
            _addProductButton(),
          ],
        ),
      ),
    );
  }

  // ================= CARD =================
  Widget _cardContainer({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Card(
      color: AppColors.card,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right, size: 20),
              ],
            ),
            const SizedBox(height: 20),
            child,
          ],
        ),
      ),
    );
  }

  // ================= STAT =================
  Widget _statItem(int value, String label, Color color) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // ================= ADD PRODUCT =================
  Widget _addProductButton() {
    return GestureDetector(
      onTap: () {
        Get.toNamed(AppRoutes.addProduct);
      },
      child: DottedBorder(
        dashPattern: const [6, 4],
        borderType: BorderType.RRect,
        radius: const Radius.circular(8),
        color: AppColors.primary,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          alignment: Alignment.center,
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add, color: AppColors.primary),
              SizedBox(width: 8),
              Text(
                'Tambah Produk Baru',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================= MENU =================
  Widget _menuItem(IconData icon, String title, {VoidCallback? onTap}) {
  return Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
    ),
    child: ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right, color: AppColors.primary),
      onTap: onTap,
    ),
  );
}
}
