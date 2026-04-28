import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:senkukoadmin/constant/app_colors.dart';
import 'package:senkukoadmin/features/products/controllers/product_controller.dart';
import 'package:senkukoadmin/routes/routes.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final productC = Get.find<ProductController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Obx(
          () => SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                _header(),
                const SizedBox(height: 24),
                _statsRow(productC),
                const SizedBox(height: 24),
                _ordersSection(),
                const SizedBox(height: 24),
                _menuSection(),
                const SizedBox(height: 24),
                _addProductButton(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==================== HEADER ====================
  Widget _header() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Selamat datang 👋',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Senkuko Admin',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A2E),
                  letterSpacing: -0.4,
                ),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: () {},
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.notifications_outlined,
              color: Color(0xFF757575),
              size: 18,
            ),
          ),
        ),
      ],
    );
  }

  // ==================== STATS ROW ====================
  Widget _statsRow(ProductController productC) {
    final total = productC.productList.length;
    final aktif = productC.productList.where((p) => p.isActive == 1).length;
    final nonAktif = total - aktif;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('Ringkasan Produk'),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _statCard(
                value: total.toString(),
                label: 'Total',
                isPrimary: true,
                onTap: () => Get.toNamed(AppRoutes.product),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _statCard(
                value: aktif.toString(),
                label: 'Aktif',
                isPrimary: false,
                onTap: () => Get.toNamed(AppRoutes.product),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _statCard(
                value: nonAktif.toString(),
                label: 'Non-Aktif',
                isPrimary: false,
                onTap: () => Get.toNamed(AppRoutes.product),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _statCard({
    required String value,
    required String label,
    required bool isPrimary,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          color: isPrimary ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: isPrimary
              ? null
              : Border.all(color: const Color.fromARGB(255, 255, 255, 255)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: isPrimary ? Colors.white : const Color(0xFF1A1A2E),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isPrimary
                    ? Colors.white.withAlpha(180)
                    : Colors.grey.shade500,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== ORDERS SECTION ====================
  Widget _ordersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _sectionLabel('Pesanan'),
            GestureDetector(
              onTap: () => Get.toNamed(AppRoutes.transaction),
              child: const Text(
                'Lihat semua',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              _orderRow(
                icon: Icons.access_time_rounded,
                title: 'Perlu Diproses',
                subtitle: 'Menunggu konfirmasi',
                isLast: false,
                onTap: () => Get.toNamed(AppRoutes.transaction),
              ),
              _orderRow(
                icon: Icons.local_shipping_outlined,
                title: 'Perlu Dikirim',
                subtitle: 'Siap untuk pengiriman',
                isLast: false,
                onTap: () => Get.toNamed(AppRoutes.transaction),
              ),
              _orderRow(
                icon: Icons.cancel_outlined,
                title: 'Pembatalan',
                subtitle: 'Perlu persetujuan',
                isLast: true,
                onTap: () => Get.toNamed(AppRoutes.transaction),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _orderRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isLast,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : const Border(
                  bottom: BorderSide(color: Color(0xFFF2F2F2)),
                ),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(12),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, color: AppColors.primary, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF9E9E9E),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              size: 16,
              color: Color(0xFFBDBDBD),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== MENU SECTION ====================
  Widget _menuSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('Menu'),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _menuCard(
                icon: Icons.inventory_2_outlined,
                label: 'Produk',
                sub: 'Kelola inventori',
                onTap: () => Get.toNamed(AppRoutes.product),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _menuCard(
                icon: Icons.local_offer_rounded,
                label: 'Promo',
                sub: 'Kelola diskon',
                onTap: () => Get.toNamed(AppRoutes.promo),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _menuCard(
                icon: Icons.confirmation_number_rounded,
                label: 'Voucher',
                sub: 'Kode kupon',
                onTap: () => Get.toNamed(AppRoutes.voucher),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _menuCard(
                icon: Icons.people_outline_rounded,
                label: 'Customer',
                sub: 'Data pelanggan',
                onTap: () => Get.toNamed(AppRoutes.customer),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _menuCard({
    required IconData icon,
    required String label,
    required String sub,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(12),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, color: AppColors.primary, size: 16),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  Text(
                    sub,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF9E9E9E),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== ADD PRODUCT ====================
  Widget _addProductButton() {
    return GestureDetector(
      onTap: () => Get.toNamed(AppRoutes.addProduct),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_rounded, color: Colors.white, size: 18),
            SizedBox(width: 6),
            Text(
              'Tambah Produk Baru',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== HELPER ====================
  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: Color(0xFF1A1A2E),
        letterSpacing: -0.1,
      ),
    );
  }
}