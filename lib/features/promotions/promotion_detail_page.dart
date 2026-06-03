import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:senkukoadmin/constant/app_back_button.dart';
import 'package:senkukoadmin/constant/app_colors.dart';
import 'package:senkukoadmin/constant/app_error_state.dart';
import 'package:senkukoadmin/features/promotions/promotion_condition_tile.dart';
import 'package:senkukoadmin/features/promotions/promotion_controller.dart';
import 'package:senkukoadmin/features/promotions/promotion_model.dart';
import 'package:senkukoadmin/features/promotions/promotion_reward_tile.dart';
import 'package:senkukoadmin/features/vouchers/voucher_card.dart';
import 'package:senkukoadmin/features/vouchers/voucher_controller.dart';
import 'package:senkukoadmin/routes/routes.dart';

class PromotionDetailPage extends StatefulWidget {
  const PromotionDetailPage({super.key});

  @override
  State<PromotionDetailPage> createState() => _PromotionDetailPageState();
}

class _PromotionDetailPageState extends State<PromotionDetailPage> {
  final _ctrl = Get.find<PromotionController>();
  late final VoucherController _voucherCtrl;
  late final String? _id;

  @override
  void initState() {
    super.initState();
    _id = Get.arguments as String?;
    _voucherCtrl = Get.find<VoucherController>();
    if (_id != null && _id.isNotEmpty) {
      _ctrl.fetchPromotionById(_id);
      _voucherCtrl.fetchVouchersForPromotion(_id);
    }
  }

  @override
  void dispose() {
    _voucherCtrl.clearPromotionVouchers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_id == null || _id.isEmpty) {
      return const Scaffold(body: Center(child: Text('ID tidak ditemukan')));
    }

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
            onTap: () => Get.toNamed(AppRoutes.promotionForm, arguments: _id),
            child: Container(
              margin: const EdgeInsets.only(right: 16, top: 10, bottom: 10),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
        if (_ctrl.isLoadingDetail.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (_ctrl.hasDetailError.value) {
          return AppErrorState(
            message: _ctrl.detailErrorMessage.value,
            onRetry: () => _ctrl.fetchPromotionById(_id),
          );
        }
        final promo = _ctrl.selectedPromotion.value;
        if (promo == null) {
          return const Center(child: Text('Data tidak ditemukan'));
        }

        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () => _ctrl.fetchPromotionById(_id),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StatusBanner(promo: promo),
                const SizedBox(height: 16),
                _infoCard(promo),
                const SizedBox(height: 12),
                _conditionsSection(promo),
                const SizedBox(height: 12),
                _rewardsSection(promo),
                const SizedBox(height: 12),
                _voucherSection(promo),
              ],
            ),
          ),
        );
      }),
    );
  }

  // ── Info card ─────────────────────────────────────────────────────────────

  Widget _infoCard(PromotionData promo) {
    final df = DateFormat('dd MMM yyyy', 'id_ID');
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            promo.name,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _codeBadge(promo.code),
              const SizedBox(width: 6),
              _typeBadge(promo.type, promo.typeLabel),
              if (promo.stackable) ...[
                const SizedBox(width: 6),
                _badge(
                  'Stackable',
                  fg: AppColors.secondary,
                  bg: AppColors.secondary.withAlpha(18),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
          Divider(height: 1, color: Colors.grey.shade100),
          const SizedBox(height: 12),
          _infoRow(
            Icons.calendar_today_outlined,
            'Periode',
            '${df.format(promo.validFrom)} – ${df.format(promo.validTo)}',
          ),
          const SizedBox(height: 8),
          _infoRow(
            Icons.repeat_rounded,
            'Pemakaian',
            promo.usageLimit == 0
                ? 'Tidak terbatas'
                : '${promo.usageCount} dari ${promo.usageLimit}x dipakai',
          ),
          if ((promo.description ?? '').isNotEmpty) ...[
            const SizedBox(height: 8),
            _infoRow(
              Icons.notes_rounded,
              'Deskripsi',
              promo.description!,
            ),
          ],
        ],
      ),
    );
  }

  // ── Conditions section ────────────────────────────────────────────────────

  Widget _conditionsSection(PromotionData promo) {
    final conditions = _ctrl.detailConditions;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(
          'SYARAT',
          count: conditions.length,
          onAdd: () => Get.toNamed(
            AppRoutes.promotionConditionForm,
            arguments: _id,
          ),
        ),
        _card(
          child: conditions.isEmpty
              ? _emptyState(
                  icon: Icons.checklist_rounded,
                  message: 'Berlaku untuk semua transaksi',
                  subtitle: 'Belum ada syarat khusus ditambahkan',
                )
              : Column(
                  children: conditions.asMap().entries.map((e) {
                    return PromotionConditionTile(
                      condition: e.value,
                      isLast: e.key == conditions.length - 1,
                      onDelete: () =>
                          _ctrl.deleteCondition(_id!, e.value.id),
                    );
                  }).toList(),
                ),
        ),
      ],
    );
  }

  // ── Rewards section ───────────────────────────────────────────────────────

  Widget _rewardsSection(PromotionData promo) {
    final rewards = _ctrl.detailRewards;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(
          'REWARD',
          count: rewards.length,
          onAdd: () => Get.toNamed(
            AppRoutes.promotionRewardForm,
            arguments: _id,
          ),
        ),
        _card(
          child: rewards.isEmpty
              ? _emptyState(
                  icon: Icons.card_giftcard_rounded,
                  message: 'Belum ada reward',
                  subtitle: 'Tambahkan reward agar promo bisa digunakan',
                  isWarning: true,
                )
              : Column(
                  children: rewards.asMap().entries.map((e) {
                    return PromotionRewardTile(
                      reward: e.value,
                      isLast: e.key == rewards.length - 1,
                      onDelete: () =>
                          _ctrl.deleteReward(_id!, e.value.id),
                    );
                  }).toList(),
                ),
        ),
      ],
    );
  }

  // ── Voucher section ───────────────────────────────────────────────────────

  static const int _voucherPreviewLimit = 5;

  Widget _voucherSection(PromotionData promo) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(
          'VOUCHER',
          addLabel: 'Terbitkan',
          onAdd: () => Get.toNamed(AppRoutes.voucherForm, arguments: promo),
        ),
        Obx(() {
          final all = _voucherCtrl.promotionVouchers;
          final isLoading = _voucherCtrl.isLoading.value;
          final preview = all.take(_voucherPreviewLimit).toList();
          final hasMore = all.length > _voucherPreviewLimit;

          if (isLoading && all.isEmpty) {
            return _card(
              child: const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          }

          if (all.isEmpty) {
            return _card(
              child: _emptyState(
                icon: Icons.confirmation_number_outlined,
                message: 'Belum ada voucher',
                subtitle: 'Terbitkan voucher pertama untuk promosi ini',
              ),
            );
          }

          return Column(
            children: [
              ...preview.map((v) => VoucherCard(
                    voucher: v,
                    onTap: () => Get.toNamed(
                      AppRoutes.voucherForm,
                      arguments: {'id': v.id, 'isEdit': true},
                    ),
                  )),
              if (hasMore)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: GestureDetector(
                    onTap: () =>
                        Get.toNamed(AppRoutes.vouchers, arguments: promo),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFF0F0F0)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Lihat Semua (${all.length})',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.arrow_forward_rounded,
                              size: 14, color: AppColors.primary),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        }),
      ],
    );
  }

  // ── Shared widgets ────────────────────────────────────────────────────────

  Widget _card({required Widget child}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFF0F0F0), width: 0.5),
        ),
        child: child,
      );

  Widget _sectionHeader(
    String label, {
    required VoidCallback onAdd,
    String addLabel = 'Tambah',
    int? count,
  }) =>
      Padding(
        padding: const EdgeInsets.only(left: 2, bottom: 8),
        child: Row(
          children: [
            Text(
              count != null ? '$label ($count)' : label,
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
              child: Row(
                children: [
                  Icon(Icons.add_rounded, size: 14, color: AppColors.primary),
                  const SizedBox(width: 3),
                  Text(
                    addLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _infoRow(IconData icon, String label, String value) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 13, color: AppColors.subtext),
          const SizedBox(width: 8),
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: const TextStyle(
                  fontSize: 12, color: Color(0xFFAAAAAA)),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1A1A2E),
              ),
            ),
          ),
        ],
      );

  Widget _emptyState({
    required IconData icon,
    required String message,
    required String subtitle,
    bool isWarning = false,
  }) {
    final color = isWarning ? AppColors.warning : AppColors.subtext;
    final bg = isWarning ? AppColors.warningBg : Colors.grey.shade50;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isWarning
                        ? AppColors.warning
                        : const Color(0xFF1A1A2E),
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                      fontSize: 11, color: Color(0xFFAAAAAA)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _codeBadge(String code) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: Colors.grey.shade300, width: 0.5),
        ),
        child: Text(
          code,
          style: const TextStyle(
            fontSize: 11,
            fontFamily: 'monospace',
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
            color: Color(0xFF1A1A2E),
          ),
        ),
      );

  Widget _typeBadge(String type, String label) {
    Color fg;
    Color bg;
    switch (type) {
      case 'discount_percent':
      case 'discount_fixed':
        fg = AppColors.success;
        bg = AppColors.successBg;
        break;
      case 'free_item':
        fg = AppColors.warning;
        bg = AppColors.warningBg;
        break;
      default:
        fg = AppColors.subtext;
        bg = AppColors.subtext.withAlpha(20);
    }
    return _badge(label, fg: fg, bg: bg);
  }

  Widget _badge(String label, {required Color fg, required Color bg}) =>
      Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(5),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: fg,
          ),
        ),
      );
}

// ── Status Banner ─────────────────────────────────────────────────────────────

class _StatusBanner extends StatelessWidget {
  final PromotionData promo;
  const _StatusBanner({required this.promo});

  @override
  Widget build(BuildContext context) {
    final Color fg;
    final Color bg;
    final String label;
    final IconData icon;

    if (!promo.isActive) {
      fg = AppColors.subtext;
      bg = Colors.grey.shade100;
      label = 'Promosi tidak aktif';
      icon = Icons.pause_circle_outline_rounded;
    } else if (promo.isExpired) {
      fg = AppColors.warning;
      bg = AppColors.warningBg;
      label = 'Promosi telah kedaluwarsa';
      icon = Icons.timer_off_outlined;
    } else {
      fg = AppColors.primary;
      bg = AppColors.primary.withAlpha(18);
      label = 'Promosi sedang berjalan';
      icon = Icons.check_circle_outline_rounded;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 15, color: fg),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}