import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:senkukoadmin/constant/app_back_button.dart';
import 'package:senkukoadmin/constant/app_colors.dart';
import 'package:senkukoadmin/features/promotions/promotion_controller.dart';
import 'package:senkukoadmin/routes/routes.dart';

class PromotionDetailPage extends StatelessWidget {
  const PromotionDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<PromotionController>();
    final String? id = Get.arguments as String?;

    if (id == null) {
      return const Scaffold(body: Center(child: Text('ID tidak ditemukan')));
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.fetchPromotionById(id);
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const Padding(
          padding: EdgeInsets.only(left: 16),
          child: AppBackButton(),
        ),
        leadingWidth: 40,
        title: const Text(
          'Detail Promosi',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.edit_outlined,
              size: 20,
              color: Colors.black54,
            ),
            onPressed: () =>
                Get.toNamed(AppRoutes.promotionForm, arguments: id),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoadingDetail.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = controller.selectedPromotion.value;
        if (data == null) {
          return const Center(child: Text('Data tidak ditemukan'));
        }

        final conditions = data['conditions'] as List? ?? [];
        final rewards = data['rewards'] as List? ?? [];
        final df = DateFormat('dd MMM yyyy', 'id_ID');

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Info ──────────────────────────────────────────────────────
              _sectionLabel('Informasi Promosi'),
              _card(
                child: Column(
                  children: [
                    _infoRow('Nama', data['name'] ?? ''),
                    _infoRow('Kode', data['code'] ?? '', mono: true),
                    _infoRow('Tipe', _typeLabel(data['type'] ?? '')),
                    if ((data['description'] ?? '').isNotEmpty)
                      _infoRow('Deskripsi', data['description']),
                    _infoRow(
                      'Berlaku',
                      '${df.format(DateTime.parse(data['valid_from']))} – ${df.format(DateTime.parse(data['valid_to']))}',
                    ),
                    _infoRow(
                      'Batas Pakai',
                      data['usage_limit'] == 0
                          ? 'Unlimited'
                          : '${data['usage_count']}/${data['usage_limit']}x',
                    ),
                    _infoRow(
                      'Stackable',
                      (data['stackable'] == 1 || data['stackable'] == true)
                          ? 'Ya'
                          : 'Tidak',
                    ),
                    _infoRow(
                      'Status',
                      (data['is_active'] == 1 || data['is_active'] == true)
                          ? 'Aktif'
                          : 'Tidak Aktif',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // ── Conditions ────────────────────────────────────────────────
              Row(
                children: [
                  Expanded(child: _sectionLabel('Syarat')),
                  GestureDetector(
                    onTap: () => Get.toNamed(
                      AppRoutes.promotionConditionForm,
                      arguments: id,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.add_circle_outline_rounded,
                          size: 16,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Tambah',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              _card(
                child: conditions.isEmpty
                    ? _emptyState(
                        'Belum ada syarat',
                        'Promo berlaku untuk semua transaksi',
                      )
                    : Column(
                        children: conditions.asMap().entries.map((entry) {
                          final c = entry.value as Map<String, dynamic>;
                          final isLast = entry.key == conditions.length - 1;
                          return _conditionTile(
                            c,
                            isLast,
                            onDelete: () =>
                                controller.deleteCondition(id, c['id']),
                          );
                        }).toList(),
                      ),
              ),

              const SizedBox(height: 12),

              // ── Rewards ───────────────────────────────────────────────────
              Row(
                children: [
                  Expanded(child: _sectionLabel('Reward')),
                  GestureDetector(
                    onTap: () => Get.toNamed(
                      AppRoutes.promotionRewardForm,
                      arguments: id,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.add_circle_outline_rounded,
                          size: 16,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Tambah',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              _card(
                child: rewards.isEmpty
                    ? _emptyState(
                        'Belum ada reward',
                        'Tambahkan reward agar promo dapat berfungsi',
                        isWarning: true,
                      )
                    : Column(
                        children: rewards.asMap().entries.map((entry) {
                          final r = entry.value as Map<String, dynamic>;
                          final isLast = entry.key == rewards.length - 1;
                          return _rewardTile(
                            r,
                            isLast,
                            onDelete: () =>
                                controller.deleteReward(id, r['id']),
                          );
                        }).toList(),
                      ),
              ),

              // Lihat Voucher dari promotion ini
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => Get.toNamed(
                    AppRoutes.vouchers,
                    arguments: id, // promotionId
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(
                    Icons.confirmation_number_outlined,
                    size: 18,
                  ),
                  label: const Text(
                    'Lihat & Kelola Voucher',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              const SizedBox(height: 24),

              // ── Danger zone ───────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () =>
                      controller.confirmDelete(id, data['name'] ?? ''),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  label: const Text(
                    'Hapus Promosi',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      }),
    );
  }

  // ── Tiles ──────────────────────────────────────────────────────────────────

  Widget _conditionTile(
    Map<String, dynamic> c,
    bool isLast, {
    required VoidCallback onDelete,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(bottom: BorderSide(color: Color(0xFFF0F0F0))),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.blue.withAlpha(20),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.rule_rounded, size: 16, color: Colors.blue),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _conditionTypeLabel(c['condition_type'] ?? ''),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${c['operator']} ${c['value']}',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onDelete,
            child: Icon(
              Icons.delete_outline_rounded,
              size: 18,
              color: Colors.red.shade400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _rewardTile(
    Map<String, dynamic> r,
    bool isLast, {
    required VoidCallback onDelete,
  }) {
    String subtitle = '';
    if (r['reward_type'] == 'free_item') {
      subtitle = 'Qty: ${r['free_qty']}';
    } else {
      subtitle =
          '${r['discount_value']} • ${_discountModeLabel(r['discount_mode'] ?? '')}';
      final maxDisc =
          double.tryParse(r['max_discount_amount']?.toString() ?? '0') ?? 0;
      if (maxDisc > 0) subtitle += ' • maks Rp$maxDisc';
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(bottom: BorderSide(color: Color(0xFFF0F0F0))),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFF2DC98E).withAlpha(20),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.card_giftcard_rounded,
              size: 16,
              color: Color(0xFF2DC98E),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _rewardTypeLabel(r['reward_type'] ?? ''),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onDelete,
            child: Icon(
              Icons.delete_outline_rounded,
              size: 18,
              color: Colors.red.shade400,
            ),
          ),
        ],
      ),
    );
  }

  // ── Shared widgets ─────────────────────────────────────────────────────────

  Widget _card({required Widget child}) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: Colors.grey.shade100),
    ),
    child: child,
  );

  Widget _sectionLabel(String label) => Padding(
    padding: const EdgeInsets.only(left: 2, bottom: 8),
    child: Text(
      label,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Colors.grey,
        letterSpacing: 0.3,
      ),
    ),
  );

  Widget _infoRow(String label, String value, {bool mono = false}) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF1A1A2E),
              fontFamily: mono ? 'monospace' : null,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _emptyState(
    String message,
    String subtitle, {
    bool isWarning = false,
  }) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: isWarning
          ? Colors.orange.withAlpha(15)
          : Colors.grey.withAlpha(15),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      children: [
        Icon(
          isWarning ? Icons.warning_amber_rounded : Icons.info_outline_rounded,
          size: 16,
          color: isWarning ? Colors.orange : Colors.grey,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  // ── Label helpers ──────────────────────────────────────────────────────────

  String _typeLabel(String type) {
    switch (type) {
      case 'discount_percent':
        return 'Diskon %';
      case 'discount_fixed':
        return 'Diskon Nominal';
      case 'free_item':
        return 'Gratis Item';
      default:
        return type;
    }
  }

  String _conditionTypeLabel(String type) {
    switch (type) {
      case 'min_transaction_amount':
        return 'Min. Total Belanja';
      case 'min_qty':
        return 'Min. Qty Item';
      case 'specific_product':
        return 'Produk Tertentu';
      case 'specific_category':
        return 'Kategori Tertentu';
      case 'member_type':
        return 'Tipe Member';
      default:
        return type;
    }
  }

  String _rewardTypeLabel(String type) {
    switch (type) {
      case 'discount_percent':
        return 'Diskon %';
      case 'discount_fixed':
        return 'Diskon Nominal';
      case 'free_item':
        return 'Gratis Item';
      default:
        return type;
    }
  }

  String _discountModeLabel(String mode) {
    switch (mode) {
      case 'per_transaction':
        return 'Per Transaksi';
      case 'per_item':
        return 'Per Item';
      default:
        return mode;
    }
  }
}
