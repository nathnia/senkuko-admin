import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:senkukoadmin/constant/app_colors.dart';
import 'package:senkukoadmin/constant/app_dialog.dart';
import 'package:senkukoadmin/constant/app_toast.dart';
import 'package:senkukoadmin/features/auth/auth_controller.dart';
import 'package:senkukoadmin/routes/routes.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              _header(context),
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
    );
  }

  // ==================== HEADER ====================
  Widget _header(BuildContext context) {
    final auth = Get.find<AuthController>();

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Selamat datang 👋',
                style: TextStyle(fontSize: 11, color: AppColors.subtext),
              ),
              const SizedBox(height: 1),
              Obx(() => Text(
                    auth.currentUser.value?.name ?? 'Admin',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.title,
                      letterSpacing: -0.3,
                    ),
                  )),
            ],
          ),
        ),
        Obx(() {
          final user = auth.currentUser.value;
          final initial = (user?.name.isNotEmpty == true)
              ? user!.name[0].toUpperCase()
              : 'A';

          return PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'logout') {
                final confirmed = await AppDialog.confirm(
                  title: 'Keluar',
                  content: 'Yakin ingin keluar dari akun ini?',
                  confirmLabel: 'Keluar',
                  confirmColor: AppColors.danger,
                );
                if (confirmed) auth.logout();
              }
            },
            color: Colors.white,
            elevation: 8,
            shadowColor: Colors.black26,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade100),
            ),
            offset: const Offset(0, 48),
            itemBuilder: (_) => [
              // header info — non-interactive
              PopupMenuItem(
                enabled: false,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.name ?? 'Admin',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.title,
                      ),
                    ),
                    if (user?.email != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        user!.email!,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.subtext,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        user?.role.name.capitalizeFirst ?? 'Admin',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(height: 1),
              PopupMenuItem<String>(
                value: 'logout',
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    Icon(Icons.logout_rounded, size: 16, color: AppColors.danger),
                    const SizedBox(width: 10),
                    Text(
                      'Keluar',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.danger,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  initial,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
          );
        }),
      ],
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
                onTap: () => Get.toNamed(
                  AppRoutes.transaction,
                  arguments: {'statusFilter': 'processing'},
                ),
              ),
              _orderRow(
                icon: Icons.local_shipping_outlined,
                title: 'Perlu Dikirim',
                subtitle: 'Siap untuk pengiriman',
                isLast: false,
                onTap: () => Get.toNamed(
                  AppRoutes.transaction,
                  arguments: {'statusFilter': 'shipped'},
                ),
              ),
              _orderRow(
                icon: Icons.cancel_outlined,
                title: 'Dibatalkan',
                subtitle: 'Transaksi dibatalkan',
                isLast: true,
                onTap: () => Get.toNamed(
                  AppRoutes.transaction,
                  arguments: {'statusFilter': 'cancelled'},
                ),
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
              : const Border(bottom: BorderSide(color: AppColors.background)),
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
                  Text(title,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.title)),
                  const SizedBox(height: 1),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.subtext)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 16, color: AppColors.subtext),
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
                onTap: () => Get.toNamed(AppRoutes.promotions),
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
                onTap: () => Get.toNamed(AppRoutes.vouchers),
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
                  Text(label,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.title)),
                  Text(sub,
                      style: const TextStyle(
                          fontSize: 10, color: AppColors.subtext)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 14, color: AppColors.subtext),
          ],
        ),
      ),
    );
  }

  // ==================== ADD PRODUCT ====================
  Widget _addProductButton() {
    return GestureDetector(
      onTap: () =>
          AppToast.show('Fitur tambah produk sedang dalam pengembangan'),
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
                  fontSize: 14),
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
        color: AppColors.title,
        letterSpacing: -0.1,
      ),
    );
  }
}