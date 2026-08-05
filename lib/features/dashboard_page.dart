import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:senkukoadmin/constant/app_colors.dart';
import 'package:senkukoadmin/constant/app_dialog.dart';
import 'package:senkukoadmin/constant/currency_formatter.dart';
import 'package:senkukoadmin/features/auth/auth_controller.dart';
import 'package:senkukoadmin/features/transactions/transaction_controller.dart';
import 'package:senkukoadmin/routes/routes.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  int _countByStatus(TransactionController c, String status) =>
      c.transactionList.where((t) => t.status == status).length;

  @override
  Widget build(BuildContext context) {
    final txC = Get.find<TransactionController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          backgroundColor: Colors.white,
          onRefresh: () => txC.fetchTransactions(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 14),
                _header(),
                const SizedBox(height: 24),
                _ordersSection(txC),
                const SizedBox(height: 24),
                _menuSection(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==================== HEADER ====================
  Widget _header() {
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
              const SizedBox(height: 2),
              Obx(() => Text(
                    auth.currentUser.value?.name ?? 'Admin',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
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
              PopupMenuItem(
                enabled: false,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    Icon(Icons.logout_rounded,
                        size: 16, color: AppColors.danger),
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
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  initial,
                  style: TextStyle(
                    fontSize: 15,
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
  Widget _ordersSection(TransactionController txC) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _sectionLabel('Transaksi'),
            GestureDetector(
              onTap: () => Get.toNamed(AppRoutes.transaction),
              child: Text(
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
            border: Border.all(color: Colors.black.withAlpha(10), width: 0.5),
          ),
          child: Obx(() {
            final pendingList = txC.transactionList
                .where((t) => t.status == 'pending_payment')
                .toList();

            final pendingTotalRupiah =
                pendingList.fold(0.0, (sum, t) => sum + t.grandTotal);

            final oldestPendingDays = pendingList.isEmpty
                ? 0
                : pendingList
                    .map((t) => DateTime.now()
                        .difference(t.transactedAt)
                        .inHours ~/
                        24)
                    .reduce((a, b) => a > b ? a : b);

            final pendingSubtitle = pendingList.isEmpty
                ? 'Menunggu konfirmasi admin'
                : 'Estimasi ${CurrencyFormatter.format(pendingTotalRupiah)}';

            final pendingWarning = oldestPendingDays >= 1
                ? 'Sudah $oldestPendingDays hari menunggu konfirmasi'
                : null;

            final processingList = txC.transactionList
                .where((t) => t.status == 'processing')
                .toList();

            final oldestProcessingDays = processingList.isEmpty
                ? 0
                : processingList
                    .map((t) => DateTime.now()
                        .difference(t.transactedAt)
                        .inHours ~/
                        24)
                    .reduce((a, b) => a > b ? a : b);

            final processingWarning = oldestProcessingDays >= 1
                ? 'Sudah $oldestProcessingDays hari belum dikemas'
                : null;

            return Column(
              children: [
                _orderRow(
                  icon: Icons.access_time_rounded,
                  title: 'COD Perlu Konfirmasi',
                  subtitle: pendingSubtitle,
                  warningText: pendingWarning,
                  count: pendingList.length,
                  isLast: false,
                  onTap: () => Get.toNamed(
                    AppRoutes.transaction,
                    arguments: {'statusFilter': 'pending_payment'},
                  ),
                ),
                _orderRow(
                  icon: Icons.inbox_rounded,
                  title: 'Perlu Dikemas',
                  subtitle: 'Menunggu dikemas & dikirim',
                  warningText: processingWarning,
                  count: processingList.length,
                  isLast: false,
                  onTap: () => Get.toNamed(
                    AppRoutes.transaction,
                    arguments: {'statusFilter': 'processing'},
                  ),
                ),
                _orderRow(
                  icon: Icons.local_shipping_outlined,
                  title: 'Dikirim',
                  subtitle: 'Pesanan sedang dikirim',
                  count: _countByStatus(txC, 'shipped'),
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
                  count: _countByStatus(txC, 'cancelled'),
                  isLast: true,
                  onTap: () => Get.toNamed(
                    AppRoutes.transaction,
                    arguments: {'statusFilter': 'cancelled'},
                  ),
                ),
              ],
            );
          }),
        ),
      ],
    );
  }

  Widget _orderRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required int count,
    required bool isLast,
    required VoidCallback onTap,
    String? warningText,
  }) {
    final hasWarning = warningText != null;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : Border(
                  bottom: BorderSide(color: AppColors.background, width: 1),
                ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(top: 1),
              decoration: BoxDecoration(
                color: (hasWarning ? AppColors.danger : AppColors.primary)
                    .withAlpha(18),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(
                icon,
                color: hasWarning ? AppColors.danger : AppColors.primary,
                size: 15,
              ),
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
                      color: AppColors.title,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.subtext,
                    ),
                  ),
                  if (hasWarning) ...[
                    const SizedBox(height: 3),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline_rounded,
                            size: 11, color: AppColors.danger),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            warningText,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: AppColors.danger,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            if (count > 0) ...[
              _badge(count, isWarning: hasWarning),
              const SizedBox(width: 6),
            ],
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child:
                  Icon(Icons.chevron_right, size: 16, color: AppColors.subtext),
            ),
          ],
        ),
      ),
    );
  }

  Widget _badge(int count, {bool isWarning = false}) {
    final color = isWarning ? AppColors.danger : AppColors.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(18),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$count',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
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
        const SizedBox(height: 8),
        _bannerMenuTile(),
      ],
    );
  }

  Widget _bannerMenuTile() {
    return GestureDetector(
      onTap: () => Get.toNamed(AppRoutes.banner),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.black.withAlpha(10), width: 0.5),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(18),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(
                Icons.image_outlined,
                color: AppColors.primary,
                size: 15,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Banner',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.title,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Kelola tampilan',
                    style: TextStyle(fontSize: 12, color: AppColors.subtext),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 16, color: AppColors.subtext),
          ],
        ),
      ),
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
          border: Border.all(color: Colors.black.withAlpha(10), width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(18),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, color: AppColors.primary, size: 15),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.title,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              sub,
              style: const TextStyle(fontSize: 12, color: AppColors.subtext),
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