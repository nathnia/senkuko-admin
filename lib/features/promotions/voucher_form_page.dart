import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:senkukoadmin/constant/app_back_button.dart';
import 'package:senkukoadmin/constant/app_colors.dart';
import 'package:senkukoadmin/features/promotions/voucher_controller.dart';
import 'package:senkukoadmin/features/promotions/voucher_model.dart';

/// arguments:
/// - Create dari menu: null
/// - Create dari promotion detail: String promotionId
/// - Edit: {'id': String, 'isEdit': true}
class VoucherFormPage extends StatelessWidget {
  const VoucherFormPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<VoucherController>();
    final args = Get.arguments;

    // parse arguments
    final bool isEdit = args is Map && args['isEdit'] == true;
    final String? editId = isEdit ? args['id'] as String? : null;
    final String? prefilledPromotionId =
        isEdit ? null : (args is String ? args : null);

    // find existing voucher data kalau edit
    final VoucherData? existing = isEdit
        ? controller.voucherList.firstWhereOrNull((v) => v.id == editId)
        : null;

    final codeCtrl = TextEditingController(text: existing?.code ?? '');
    final promotionIdCtrl = TextEditingController(
        text: existing?.promotionId ?? prefilledPromotionId ?? '');
    final usageLimitCtrl =
        TextEditingController(text: existing?.usageLimit.toString() ?? '1');
    final status = (existing?.status ?? 'active').obs;

    void submit() {
      if (codeCtrl.text.isEmpty) {
        return;
      }

      if (isEdit && editId != null) {
        controller.updateVoucher(editId, {
          'code': codeCtrl.text.trim().toUpperCase(),
          'status': status.value,
          'usage_limit': int.tryParse(usageLimitCtrl.text) ?? 1,
        });
      } else {
        if (promotionIdCtrl.text.isEmpty) return;
        controller.createVoucher({
          'promotion_id': promotionIdCtrl.text.trim(),
          'code': codeCtrl.text.trim().toUpperCase(),
          'usage_limit': int.tryParse(usageLimitCtrl.text) ?? 1,
        });
      }
    }

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
                  // promotion_id — hanya di create mode
                  if (!isEdit) ...[
                    _fieldLabel('Promotion ID'),
                    const SizedBox(height: 4),
                    // kalau pre-filled dari promotion detail → readonly
                    prefilledPromotionId != null
                        ? Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(10),
                              border:
                                  Border.all(color: Colors.grey.shade200),
                            ),
                            child: Text(
                              prefilledPromotionId,
                              style: const TextStyle(
                                fontSize: 13,
                                fontFamily: 'monospace',
                                color: Colors.grey,
                              ),
                            ),
                          )
                        : TextField(
                            controller: promotionIdCtrl,
                            style: const TextStyle(fontSize: 13),
                            decoration: _inputDecoration(
                                hint: 'UUID promotion'),
                          ),
                    const SizedBox(height: 14),
                  ],

                  _fieldLabel('Kode Voucher'),
                  const SizedBox(height: 6),
                  TextField(
                    controller: codeCtrl,
                    textCapitalization: TextCapitalization.characters,
                    style: const TextStyle(fontSize: 13),
                    decoration:
                        _inputDecoration(hint: 'VOUCHER-SPESIAL-001'),
                  ),
                  const SizedBox(height: 14),

                  _fieldLabel('Batas Pemakaian'),
                  const SizedBox(height: 6),
                  TextField(
                    controller: usageLimitCtrl,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 13),
                    decoration: _inputDecoration(hint: '1'),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '0 = unlimited, 1 = sekali pakai',
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey.shade500),
                  ),

                  // status — hanya di edit mode
                  if (isEdit) ...[
                    const SizedBox(height: 14),
                    _fieldLabel('Status'),
                    const SizedBox(height: 6),
                    Obx(() => DropdownButtonFormField<String>(
                          value: status.value,
                          decoration: _inputDecoration(),
                          items: const [
                            DropdownMenuItem(
                                value: 'active', child: Text('Aktif')),
                            DropdownMenuItem(
                                value: 'inactive',
                                child: Text('Tidak Aktif')),
                          ],
                          onChanged: (v) => status.value = v!,
                        )),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),

            Obx(() => SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed:
                        controller.isSubmitting.value ? null : submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: controller.isSubmitting.value
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : Text(
                            isEdit ? 'Simpan Perubahan' : 'Terbitkan',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                  ),
                )),
          ],
        ),
      ),
    );
  }

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

  Widget _fieldLabel(String label) => Text(
        label,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
      );

  InputDecoration _inputDecoration({String? hint}) => InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.primary.withAlpha(80)),
        ),
      );
}