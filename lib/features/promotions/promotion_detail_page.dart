import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:senkukoadmin/constant/app_back_button.dart';
import 'package:senkukoadmin/constant/app_colors.dart';
import 'package:senkukoadmin/features/promotions/promotion_controller.dart';

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
        backgroundColor: AppColors.background,
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
      ),
      body: Obx(() {
        if (controller.isLoadingDetail.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = controller.selectedPromotion.value;
        if (data == null) {
          return const Center(child: Text('Data tidak ditemukan'));
        }

        final conditions = controller.detailConditions;
        final rewards = controller.detailRewards;

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
                    _infoRow(
                      'Tipe',
                      controller.promotionTypeLabel(data['type'] ?? ''),
                    ),
                    if ((data['description'] ?? '').toString().isNotEmpty)
                      _infoRow('Deskripsi', data['description'].toString()),
                    _infoRow('Berlaku', controller.detailValidPeriod),
                    _infoRow('Batas Pakai', controller.detailUsageDisplay),
                    _infoRow('Stackable', controller.detailStackableLabel),
                    _infoRow('Status', controller.detailStatusLabel),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // ── Conditions ────────────────────────────────────────────────
              _sectionLabel('Syarat (${conditions.length})'),
              _card(
                child: conditions.isEmpty
                    ? _emptyState(
                        'Belum ada syarat',
                        'Promo berlaku untuk semua transaksi',
                      )
                    : Column(
                        children: conditions.asMap().entries.map((entry) {
                          return _conditionTile(
                            controller,
                            entry.value,
                            isLast: entry.key == conditions.length - 1,
                          );
                        }).toList(),
                      ),
              ),

              const SizedBox(height: 12),

              // ── Rewards ───────────────────────────────────────────────────
              _sectionLabel('Reward (${rewards.length})'),
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
                            controller,
                            entry.value,
                            isLast: entry.key == rewards.length - 1,
                          );
                        }).toList(),
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
    PromotionController controller,
    Map<String, dynamic> c, {
    required bool isLast,
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
              color: AppColors.primary.withAlpha(15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.rule_rounded, size: 16, color: AppColors.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  controller.conditionTypeLabel(c['condition_type'] ?? ''),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${c['operator']} ${c['value']}',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
                if ((c['target_id'] ?? '').toString().isNotEmpty)
                  Text(
                    'Target: ${c['target_id']}',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _rewardTile(
    PromotionController controller,
    Map<String, dynamic> r, {
    required bool isLast,
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
                  controller.rewardTypeLabel(r['reward_type'] ?? ''),
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
        color: Colors.black54,
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
}
