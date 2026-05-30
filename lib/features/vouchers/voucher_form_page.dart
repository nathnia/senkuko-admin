import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:senkukoadmin/constant/app_back_button.dart';
import 'package:senkukoadmin/constant/app_colors.dart';
import 'package:senkukoadmin/constant/app_dropdown.dart';
import 'package:senkukoadmin/constant/app_textfield.dart';
import 'package:senkukoadmin/constant/app_toast.dart';
import 'package:senkukoadmin/features/vouchers/voucher_controller.dart';
import 'package:senkukoadmin/features/vouchers/voucher_model.dart';

/// arguments:
///   null                              → create (standalone)
///   String promotionId                → create pre-filled from promotion detail
///   {'id': String, 'isEdit': true}    → edit existing voucher
class VoucherFormPage extends StatefulWidget {
  const VoucherFormPage({super.key});

  @override
  State<VoucherFormPage> createState() => _VoucherFormPageState();
}

class _VoucherFormPageState extends State<VoucherFormPage> {
  final controller = Get.find<VoucherController>();

  // Controllers now safely owned by State — disposed in dispose()
  final _codeC = TextEditingController();
  final _promotionIdC = TextEditingController();
  final _usageLimitC = TextEditingController(text: '1');
  final _status = 'active'.obs;

  late final bool _isEdit;
  late final String? _editId;
  late final String? _prefilledPromotionId;
  VoucherData? _existing;

  @override
  void initState() {
    super.initState();

    final args = Get.arguments;
    _isEdit = args is Map && args['isEdit'] == true;
    _editId = _isEdit ? args['id'] as String? : null;
    _prefilledPromotionId = _isEdit ? null : (args is String ? args : null);

    _existing = _isEdit
        ? controller.voucherList.firstWhereOrNull((v) => v.id == _editId)
        : null;

    // Populate fields synchronously — no addPostFrameCallback needed
    _codeC.text = _existing?.code ?? '';
    _promotionIdC.text =
        _existing?.promotionId ?? _prefilledPromotionId ?? '';
    _usageLimitC.text = _existing?.usageLimit.toString() ?? '1';
    _status.value = _existing?.status ?? 'active';
  }

  @override
  void dispose() {
    _codeC.dispose();
    _promotionIdC.dispose();
    _usageLimitC.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_codeC.text.trim().isEmpty) {
      AppToast.show('Kode voucher harus diisi');
      return;
    }

    if (_isEdit && _editId != null) {
      final success = await controller.updateVoucher(_editId, {
        'code': _codeC.text.trim().toUpperCase(),
        'status': _status.value,
        'usage_limit': int.tryParse(_usageLimitC.text) ?? 1,
      });
      if (success) Get.back();
      return;
    }

    if (_promotionIdC.text.trim().isEmpty) {
      AppToast.show('Promotion ID harus diisi');
      return;
    }
    final success = await controller.createVoucher({
      'promotion_id': _promotionIdC.text.trim(),
      'code': _codeC.text.trim().toUpperCase(),
      'usage_limit': int.tryParse(_usageLimitC.text) ?? 1,
    });
    if (success) Get.back();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: const AppBackButton(),
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
                  // ── Promotion ID (create mode only) ──────────────────────
                  if (!_isEdit) ...[
                    const SizedBox(height: 6),
                    _prefilledPromotionId != null
                        ? _readonlyField(_prefilledPromotionId)
                        : AppTextField(
                            hint: 'UUID promotion',
                            controller: _promotionIdC,
                          ),
                    const SizedBox(height: 12),
                  ],

                  // ── Kode Voucher ─────────────────────────────────────────
                  const SizedBox(height: 6),
                  AppTextField(
                    hint: 'VOUCHER-SPESIAL-001',
                    controller: _codeC,
                    textCapitalization: TextCapitalization.characters,
                  ),
                  const SizedBox(height: 12),

                  // ── Batas Pemakaian ──────────────────────────────────────
                  const SizedBox(height: 6),
                  AppTextField(
                    hint: '1',
                    controller: _usageLimitC,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '0 = unlimited  •  1 = sekali pakai',
                    style:
                        TextStyle(fontSize: 11, color: AppColors.subtext),
                  ),

                  // ── Status (edit mode only) ──────────────────────────────
                  if (_isEdit) ...[
                    const SizedBox(height: 12),
                    Obx(
                      () => AppDropdown<String>(
                        label: 'Status',
                        value: _status.value,
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
                        onChanged: (v) => _status.value = v!,
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
                  onPressed:
                      controller.isSubmitting.value ? null : _submit,
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
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  Widget _readonlyField(String value) => Container(
        width: double.infinity,
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontFamily: 'monospace',
            color: Colors.grey.shade600,
          ),
        ),
      );

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