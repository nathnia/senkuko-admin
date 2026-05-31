import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:senkukoadmin/constant/app_back_button.dart';
import 'package:senkukoadmin/constant/app_colors.dart';
import 'package:senkukoadmin/constant/app_dropdown.dart';
import 'package:senkukoadmin/constant/app_textfield.dart';
import 'package:senkukoadmin/features/products/widgets/unsaved_changes_dialog.dart';
import 'package:senkukoadmin/features/promotions/promotion_model.dart';
import 'package:senkukoadmin/features/promotions/promotion_picker_sheet.dart';
import 'package:senkukoadmin/features/vouchers/voucher_controller.dart';

/// arguments:
///   null                              → create (standalone, user picks promotion)
///   PromotionData                     → create pre-filled from promotion detail
///   {'id': String, 'isEdit': true}    → edit existing voucher
class VoucherFormPage extends StatefulWidget {
  const VoucherFormPage({super.key});

  @override
  State<VoucherFormPage> createState() => _VoucherFormPageState();
}

class _VoucherFormPageState extends State<VoucherFormPage> {
  final controller = Get.find<VoucherController>();

  late final bool _isEdit;
  late final String? _editId;
  /// Non-null when navigated from a promotion detail page.
  late final PromotionData? _prefilledPromotion;

  @override
  void initState() {
    super.initState();

    final args = Get.arguments;
    _isEdit = args is Map && args['isEdit'] == true;
    _editId = _isEdit ? args['id'] as String? : null;
    _prefilledPromotion = _isEdit ? null : (args is PromotionData ? args : null);

    if (_isEdit && _editId != null) {
      final existing = controller.voucherList.firstWhereOrNull(
        (v) => v.id == _editId,
      );
      if (existing != null) {
        controller.loadFromVoucher(existing);
      }
    } else {
      controller.resetForm();
      if (_prefilledPromotion != null) {
        controller.promotionIdC.text = _prefilledPromotion.id;
        controller.selectedPromotionObs.value = _prefilledPromotion;
      }
    }
  }

  Future<bool> _confirmLeave() async {
    if (!controller.isDirty.value) return true;
    return UnsavedChangesDialog.show(title: 'Voucher belum disimpan');
  }

  Future<void> _openPromotionPicker() async {
    final picked = await PromotionPickerSheet.show(context);
    if (picked == null) return;
    controller.promotionIdC.text = picked.id;
    controller.selectedPromotionObs.value = picked;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (!_isEdit) {
          Get.back();
          return;
        }
        if (await _confirmLeave()) Get.back();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: AppBackButton(
            onTap: () async {
              if (!_isEdit) {
                Get.back();
                return;
              }
              if (await _confirmLeave()) Get.back();
            },
          ),
          title: Text(
            _isEdit ? 'Edit Voucher' : 'Terbitkan Voucher',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Promotion picker (create mode only) ──────────────
                    if (!_isEdit) _promotionPickerField(),

                    // ── Kode Voucher ──────────────────────────────────────
                    AppTextField(
                      label: 'Kode Voucher',
                      hint: 'cth: VOUCHER-SPESIAL-001',
                      controller: controller.codeC,
                      textCapitalization: TextCapitalization.characters,
                    ),

                    // ── Batas Pemakaian ───────────────────────────────────
                    AppTextField(
                      label: 'Batas Pemakaian',
                      hint: 'cth: 1',
                      controller: controller.usageLimitC,
                      keyboardType: TextInputType.number,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 2, bottom: 10),
                      child: Text(
                        '0 = unlimited  •  1 = sekali pakai',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.subtext,
                        ),
                      ),
                    ),

                    // ── Status (edit mode only) ───────────────────────────
                    if (_isEdit)
                      Obx(
                        () => AppDropdown<String>(
                          label: 'Status',
                          value: controller.status.value,
                          items: const [
                            DropdownMenuItem(
                              value: 'active',
                              child: Text('Aktif'),
                            ),
                            DropdownMenuItem(
                              value: 'inactive',
                              child: Text('Tidak Aktif'),
                            ),
                          ],
                          onChanged: (v) => controller.status.value = v!,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Obx(
                () => SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    onPressed:
                        controller.isSubmitting.value ||
                            !controller.isDirty.value
                        ? null
                        : () async {
                            final success = _isEdit
                                ? await controller.updateVoucher(_editId!)
                                : await controller.createVoucher();
                            if (!mounted) return;
                            if (success) Get.back();
                          },
                    child: controller.isSubmitting.value
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            _isEdit ? 'Simpan Perubahan' : 'Terbitkan',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Promotion picker field ────────────────────────────────────────────────

  Widget _promotionPickerField() {
    // When opened from promotion detail the promotion is pre-filled and locked.
    final bool isLocked = _prefilledPromotion != null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Promosi',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.subtext,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 5),
          Obx(() {
            final selected = controller.selectedPromotionObs.value;
            return GestureDetector(
              onTap: isLocked ? null : _openPromotionPicker,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: selected != null && !isLocked
                        ? AppColors.primary.withAlpha(80)
                        : Colors.transparent,
                    width: 1,
                  ),
                ),
                child: selected == null
                    ? Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Pilih promosi...',
                              style: TextStyle(
                                color: AppColors.subtext,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.arrow_drop_down_rounded,
                            color: Colors.grey.shade400,
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withAlpha(15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.local_offer_rounded,
                              size: 15,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  selected.name,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1A1A2E),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  selected.code,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontFamily: 'monospace',
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          // Show lock icon when pre-filled, clear button otherwise
                          if (isLocked)
                            Icon(
                              Icons.lock_outline_rounded,
                              size: 14,
                              color: Colors.grey.shade400,
                            )
                          else
                            GestureDetector(
                              onTap: () {
                                controller.selectedPromotionObs.value = null;
                                controller.promotionIdC.clear();
                              },
                              child: Icon(
                                Icons.close_rounded,
                                size: 16,
                                color: Colors.grey.shade400,
                              ),
                            ),
                        ],
                      ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────


  Widget _card({required Widget child}) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: Colors.grey.shade100, width: 0.5),
    ),
    child: child,
  );
}