import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:senkukoadmin/constant/app_back_button.dart';
import 'package:senkukoadmin/constant/app_colors.dart';
import 'package:senkukoadmin/constant/app_dropdown.dart';
import 'package:senkukoadmin/constant/app_textfield.dart';
import 'package:senkukoadmin/features/promotions/voucher_controller.dart';
import 'package:senkukoadmin/features/promotions/voucher_model.dart';
import 'package:senkukoadmin/routes/routes.dart';

/// arguments:
///   null                          → create (standalone)
///   String promotionId            → create pre-filled from promotion detail
///   {'id': String, 'isEdit': true} → edit existing voucher
class VoucherFormPage extends StatelessWidget {
  VoucherFormPage({super.key});

  final controller = Get.find<VoucherController>();

  final codeC = TextEditingController();
  final promotionIdC = TextEditingController();
  final usageLimitC = TextEditingController(text: '1');
  final status = 'active'.obs;

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments;
    final bool isEdit = args is Map && args['isEdit'] == true;
    final String? editId = isEdit ? args['id'] as String? : null;
    final String? prefilledPromotionId = isEdit
        ? null
        : (args is String ? args : null);

    final VoucherData? existing = isEdit
        ? controller.voucherList.firstWhereOrNull((v) => v.id == editId)
        : null;

    // populate fields once
    WidgetsBinding.instance.addPostFrameCallback((_) {
      codeC.text = existing?.code ?? '';
      promotionIdC.text = existing?.promotionId ?? prefilledPromotionId ?? '';
      usageLimitC.text = existing?.usageLimit.toString() ?? '1';
      status.value = existing?.status ?? 'active';
    });

    void submit() {
      if (codeC.text.trim().isEmpty) return;

      if (isEdit && editId != null) {
        controller
            .updateVoucher(editId, {
              'code': codeC.text.trim().toUpperCase(),
              'status': status.value,
              'usage_limit': int.tryParse(usageLimitC.text) ?? 1,
            })
            .then((success) {
              if (success) Get.back();
            });
      } else {
        if (promotionIdC.text.trim().isEmpty) return;
        controller
            .createVoucher({
              'promotion_id': promotionIdC.text.trim(),
              'code': codeC.text.trim().toUpperCase(),
              'usage_limit': int.tryParse(usageLimitC.text) ?? 1,
            })
            .then((success) {
              if (success) {
                Get.until((route) => route.settings.name == AppRoutes.vouchers);
              }
            });
      }
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: const AppBackButton(),
        title: Text(
          isEdit ? 'Edit Voucher' : 'Terbitkan Voucher',
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
                  // Promotion ID — create mode only
                  if (!isEdit) ...[
                    const SizedBox(height: 6),
                    prefilledPromotionId != null
                        ? Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              prefilledPromotionId,
                              style: TextStyle(
                                fontSize: 13,
                                fontFamily: 'monospace',
                                color: Colors.grey.shade600,
                              ),
                            ),
                          )
                        : AppTextField(
                            hint: 'UUID promotion',
                            controller: promotionIdC,
                          ),
                    const SizedBox(height: 12),
                  ],

                  const SizedBox(height: 6),
                  AppTextField(
                    hint: 'VOUCHER-SPESIAL-001',
                    controller: codeC,
                    textCapitalization: TextCapitalization.characters,
                  ),
                  const SizedBox(height: 12),

                  const SizedBox(height: 6),
                  AppTextField(
                    hint: '1',
                    controller: usageLimitC,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '0 = unlimited  •  1 = sekali pakai',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),

                  // Status — edit mode only
                  if (isEdit) ...[
                    const SizedBox(height: 12),
                    const SizedBox(height: 6),
                    Obx(
                      () => AppDropdown<String>(
                        value: status.value,
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
                        onChanged: (v) => status.value = v!,
                      ),
                    ),
                  ],
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
                  onPressed: controller.isSubmitting.value ? null : submit,
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
                          isEdit ? 'Simpan Perubahan' : 'Terbitkan',
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
    );
  }

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
