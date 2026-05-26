import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:senkukoadmin/constant/app_back_button.dart';
import 'package:senkukoadmin/constant/app_colors.dart';
import 'package:senkukoadmin/constant/app_error_state.dart';
import 'package:senkukoadmin/features/promotions/promotion_controller.dart';
import 'package:senkukoadmin/features/promotions/promotion_model.dart';
import 'package:senkukoadmin/routes/routes.dart';

class PromotionDetailPage extends StatelessWidget {
  PromotionDetailPage({super.key});

  final controller = Get.find<PromotionController>();

  @override
  Widget build(BuildContext context) {
    final String? id = Get.arguments as String?;

    if (id == null || id.isEmpty) {
      return const Scaffold(body: Center(child: Text('ID tidak ditemukan')));
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.fetchPromotionById(id);
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: const AppBackButton(),
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
          GestureDetector(
            onTap: () => Get.toNamed(AppRoutes.promotionForm, arguments: id),
            child: Container(
              margin: const EdgeInsets.only(right: 16, top: 10, bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  Icon(Icons.edit_rounded, size: 13, color: Colors.white),
                  SizedBox(width: 4),
                  Text(
                    'Edit',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoadingDetail.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.hasDetailError.value) {
          return AppErrorState(
            message: controller.detailErrorMessage.value,
            onRetry: () => controller.fetchPromotionById(id),
          );
        }
        final promo = controller.selectedPromotion.value;
        if (promo == null) {
          return const Center(child: Text('Data tidak ditemukan'));
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionLabel('Informasi Promosi'),
              _infoCard(promo),
              const SizedBox(height: 12),
              _conditionsSection(id, promo),
              const SizedBox(height: 12),
              _rewardsSection(id, promo),
              const SizedBox(height: 12),
              // _voucherButton(id),
              const SizedBox(height: 12),
              _deleteButton(id, promo.name),
              const SizedBox(height: 24),
            ],
          ),
        );
      }),
    );
  }

  // ── Info card ──────────────────────────────────────────────────────────────

  Widget _infoCard(PromotionData promo) {
    return _card(
      child: Column(
        children: [
          _infoRow('Nama', promo.name),
          _infoRow('Kode', promo.code, mono: true),
          _infoRow('Tipe', promo.typeLabel),
          if ((promo.description ?? '').isNotEmpty)
            _infoRow('Deskripsi', promo.description!),
          _infoRow('Berlaku', controller.detailValidPeriod),
          _infoRow('Batas Pakai', controller.detailUsageDisplay),
          _infoRow('Stackable', controller.detailStackableLabel),
          _infoRow('Status', controller.detailStatusLabel),
        ],
      ),
    );
  }

  // ── Conditions section ────────────────────────────────────────────────────

  Widget _conditionsSection(String id, PromotionData promo) {
    final conditions = controller.detailConditions;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(
          'Syarat (${conditions.length})',
          onAdd: () =>
              Get.toNamed(AppRoutes.promotionConditionForm, arguments: id),
        ),
        _card(
          child: conditions.isEmpty
              ? _emptyState(
                  'Belum ada syarat',
                  'Promo berlaku untuk semua transaksi',
                )
              : Column(
                  children: conditions.asMap().entries.map((entry) {
                    return _conditionTile(
                      entry.value,
                      isLast: entry.key == conditions.length - 1,
                      onDelete: () =>
                          controller.deleteCondition(id, entry.value.id),
                    );
                  }).toList(),
                ),
        ),
      ],
    );
  }

  // ── Rewards section ───────────────────────────────────────────────────────

  Widget _rewardsSection(String id, PromotionData promo) {
    final rewards = controller.detailRewards;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(
          'Reward (${rewards.length})',
          onAdd: () =>
              Get.toNamed(AppRoutes.promotionRewardForm, arguments: id),
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
                    return _rewardTile(
                      entry.value,
                      isLast: entry.key == rewards.length - 1,
                      onDelete: () =>
                          controller.deleteReward(id, entry.value.id),
                    );
                  }).toList(),
                ),
        ),
      ],
    );
  }

  // ── Bottom buttons ─────────────────────────────────────────────────────────

  // Widget _voucherButton(String id) {
  //   return SizedBox(
  //     width: double.infinity,
  //     child: OutlinedButton.icon(
  //       onPressed: () =>
  //           Get.toNamed(AppRoutes.vouchers, arguments: id),
  //       style: OutlinedButton.styleFrom(
  //         foregroundColor: AppColors.primary,
  //         side: BorderSide(color: AppColors.primary),
  //         shape: RoundedRectangleBorder(
  //             borderRadius: BorderRadius.circular(10)),
  //         padding: const EdgeInsets.symmetric(vertical: 12),
  //       ),
  //       icon: const Icon(Icons.confirmation_number_outlined, size: 18),
  //       label: const Text(
  //         'Lihat & Kelola Voucher',
  //         style: TextStyle(fontWeight: FontWeight.w600),
  //       ),
  //     ),
  //   );
  // }

  Widget _deleteButton(String id, String name) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => controller.confirmDelete(id, name),
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
    );
  }

  // ── Tiles ──────────────────────────────────────────────────────────────────

  Widget _conditionTile(
    PromotionCondition c, {
    required bool isLast,
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
                  c.conditionTypeLabel,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${c.operatorLabel} ${c.value}',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
                if ((c.targetId ?? '').isNotEmpty)
                  Text(
                    'Target: ${c.targetId}',
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
    PromotionReward r, {
    required bool isLast,
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
                  r.rewardTypeLabel,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  controller.rewardSubtitle(r),
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
      border: Border.all(color: Colors.grey.shade100, width: 0.5),
    ),
    child: child,
  );

  Widget _sectionLabel(String label) => Padding(
    padding: const EdgeInsets.only(left: 2, bottom: 8),
    child: Text(
      label,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: Colors.black54,
        letterSpacing: 0.5,
      ),
    ),
  );

  Widget _sectionHeader(String label, {required VoidCallback onAdd}) => Padding(
    padding: const EdgeInsets.only(left: 2, bottom: 8),
    child: Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Colors.black54,
            letterSpacing: 0.5,
          ),
        ),
        const Spacer(),
        GestureDetector(
          onTap: onAdd,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.add_rounded, size: 13, color: Colors.white),
                SizedBox(width: 4),
                Text(
                  'Tambah',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
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
}
