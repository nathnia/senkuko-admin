import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:senkukoadmin/constant/app_back_button.dart';
import 'package:senkukoadmin/constant/app_colors.dart';
import 'package:senkukoadmin/features/promotions/promotion_controller.dart';

class PromotionFormPage extends StatelessWidget {
  const PromotionFormPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<PromotionController>();
    final String? editId = Get.arguments as String?;
    final isEdit = editId != null;

    controller.initForm(isEdit ? controller.selectedPromotion.value : null);

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
          isEdit ? 'Edit Promosi' : 'Buat Promosi',
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: controller.formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionLabel('Informasi Dasar'),
              _card(
                child: Column(
                  children: [
                    _field(
                      label: 'Nama Promosi',
                      ctrl: controller.nameCtrl,
                      hint: 'Diskon Akhir Tahun',
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Wajib diisi' : null,
                    ),
                    const SizedBox(height: 14),
                    _field(
                      label: 'Kode Promo',
                      ctrl: controller.codeCtrl,
                      hint: 'DISKON10',
                      textCapitalization: TextCapitalization.characters,
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Wajib diisi' : null,
                    ),
                    const SizedBox(height: 14),
                    _fieldLabel('Tipe Promosi'),
                    const SizedBox(height: 6),
                    Obx(
                      () => DropdownButtonFormField<String>(
                        value: controller.formType.value,
                        decoration: _inputDecoration(),
                        items: const [
                          DropdownMenuItem(
                            value: 'discount_percent',
                            child: Text('Diskon %'),
                          ),
                          DropdownMenuItem(
                            value: 'discount_fixed',
                            child: Text('Diskon Nominal'),
                          ),
                          DropdownMenuItem(
                            value: 'free_item',
                            child: Text('Gratis Item'),
                          ),
                        ],
                        onChanged: (v) => controller.formType.value = v!,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _field(
                      label: 'Deskripsi (opsional)',
                      ctrl: controller.descCtrl,
                      hint: 'Deskripsi singkat',
                      maxLines: 2,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),
              _sectionLabel('Periode & Batas'),
              _card(
                child: Column(
                  children: [
                    _field(
                      label: 'Batas Pemakaian (0 = unlimited)',
                      ctrl: controller.usageLimitCtrl,
                      hint: '0',
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: Obx(
                            () => _datePicker(
                              context: context,
                              label: 'Berlaku Dari',
                              date: controller.formValidFrom.value,
                              onTap: () => _pickDate(
                                context,
                                controller,
                                isFrom: true,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Obx(
                            () => _datePicker(
                              context: context,
                              label: 'Berlaku Hingga',
                              date: controller.formValidTo.value,
                              onTap: () => _pickDate(
                                context,
                                controller,
                                isFrom: false,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),
              _sectionLabel('Pengaturan'),
              _card(
                child: Column(
                  children: [
                    Obx(
                      () => _toggleTile(
                        label: 'Aktif',
                        subtitle: 'Promo dapat digunakan',
                        value: controller.formIsActive.value,
                        onChanged: (v) => controller.formIsActive.value = v,
                      ),
                    ),
                    const Divider(height: 1, color: Color(0xFFF0F0F0)),
                    Obx(
                      () => _toggleTile(
                        label: 'Stackable',
                        subtitle: 'Bisa digabung dengan promo lain',
                        value: controller.formStackable.value,
                        onChanged: (v) => controller.formStackable.value = v,
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
                    onPressed: controller.isSubmitting.value
                        ? null
                        : () => controller.submitForm(editId),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
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
                            isEdit ? 'Simpan Perubahan' : 'Buat Promosi',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ── Date picker ────────────────────────────────────────────────────────────

  static Future<void> _pickDate(
    BuildContext context,
    PromotionController controller, {
    required bool isFrom,
  }) async {
    final initial = isFrom
        ? (controller.formValidFrom.value ?? DateTime.now())
        : (controller.formValidTo.value ?? DateTime.now());

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (context, child) => Theme(
        data: ThemeData(
          colorScheme: ColorScheme.light(
            primary: AppColors.primary,
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      if (isFrom) {
        controller.formValidFrom.value = picked;
      } else {
        controller.formValidTo.value = picked;
      }
    }
  }

  // ── UI helpers ─────────────────────────────────────────────────────────────

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

  Widget _fieldLabel(String label) => Text(
        label,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
      );

  Widget _field({
    required String label,
    required TextEditingController ctrl,
    String? hint,
    TextInputType? keyboardType,
    int maxLines = 1,
    TextCapitalization textCapitalization = TextCapitalization.none,
    String? Function(String?)? validator,
  }) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _fieldLabel(label),
          const SizedBox(height: 6),
          TextFormField(
            controller: ctrl,
            keyboardType: keyboardType,
            maxLines: maxLines,
            textCapitalization: textCapitalization,
            validator: validator,
            style: const TextStyle(fontSize: 13),
            decoration: _inputDecoration(hint: hint),
          ),
        ],
      );

  Widget _datePicker({
    required BuildContext context,
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _fieldLabel(label),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: onTap,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 13,
                    color: Colors.grey.shade500,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    date != null
                        ? '${date.day}/${date.month}/${date.year}'
                        : 'Pilih tanggal',
                    style: TextStyle(
                      fontSize: 13,
                      color: date != null
                          ? const Color(0xFF1A1A2E)
                          : Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );

  Widget _toggleTile({
    required String label,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),
            Switch.adaptive(
              value: value,
              onChanged: onChanged,
              activeColor: AppColors.primary,
            ),
          ],
        ),
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