import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:senkukoadmin/constant/app_back_button.dart';
import 'package:senkukoadmin/constant/app_colors.dart';
import 'package:senkukoadmin/features/promotions/promotion_controller.dart';
import 'package:senkukoadmin/routes/routes.dart';

class PromotionFormPage extends StatelessWidget {
  PromotionFormPage({super.key});

  final controller = Get.find<PromotionController>();

  @override
  Widget build(BuildContext context) {
    final String? editId = Get.arguments as String?;
    final bool isEdit = editId != null;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (isEdit) {
        final promo = controller.selectedPromotion.value;
        if (promo != null) controller.loadFormFromPromotion(promo);
      } else {
        controller.resetForm();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: const AppBackButton(),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _card(title: 'INFORMASI PROMOSI', child: _infoFields()),
            const SizedBox(height: 12),
            _card(title: 'PERIODE & BATAS', child: _periodFields(context)),
            const SizedBox(height: 12),
            _card(title: 'PENGATURAN', child: _settingsFields()),
            const SizedBox(height: 24),
            _submitButton(isEdit, editId),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ===================== SECTIONS =====================

  Widget _infoFields() {
    return Column(
      children: [
        _input(controller.nameC, 'Nama Promosi'),
        _input(
          controller.codeC,
          'Kode Promo',
          textCapitalization: TextCapitalization.characters,
        ),
        Obx(() => _typeSelector()),
        _input(controller.descC, 'Deskripsi (opsional)', maxLines: 2),
      ],
    );
  }

  Widget _typeSelector() {
    final labels = {
      'discount_percent': 'Diskon %',
      'discount_fixed': 'Diskon Nominal',
      'free_item': 'Gratis Item',
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () => _openTypeSheet(),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  labels[controller.selectedType.value] ?? 'Tipe Promosi',
                  style: TextStyle(fontSize: 14, color: Colors.black87),
                ),
              ),
              Icon(Icons.arrow_drop_down_rounded, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }

  void _openTypeSheet() {
    final options = {
      'discount_percent': 'Diskon %',
      'discount_fixed': 'Diskon Nominal',
      'free_item': 'Gratis Item',
    };

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Tipe Promosi',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
            const SizedBox(height: 10),
            ...options.entries.map(
              (e) => ListTile(
                title: Text(e.value, style: const TextStyle(fontSize: 14)),
                trailing: controller.selectedType.value == e.key
                    ? Icon(Icons.check_rounded, color: AppColors.primary)
                    : null,
                onTap: () {
                  controller.selectedType.value = e.key;
                  Get.back();
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _periodFields(BuildContext context) {
    return Column(
      children: [
        _input(
          controller.usageLimitC,
          'Batas Pemakaian (0 = unlimited)',
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: Obx(
                () => _datePicker(
                  context: context,
                  hint: 'Berlaku Dari',
                  date: controller.validFrom.value,
                  onTap: () => _pickDate(context, isFrom: true),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Obx(
                () => _datePicker(
                  context: context,
                  hint: 'Berlaku Hingga',
                  date: controller.validTo.value,
                  onTap: () => _pickDate(context, isFrom: false),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _settingsFields() {
    return Column(
      children: [
        Obx(
          () => _toggleTile(
            label: 'Aktif',
            subtitle: 'Promo dapat digunakan',
            value: controller.isActive.value,
            onChanged: (v) => controller.isActive.value = v,
          ),
        ),
        Divider(height: 1, color: Colors.grey.shade100),
        Obx(
          () => _toggleTile(
            label: 'Stackable',
            subtitle: 'Bisa digabung dengan promo lain',
            value: controller.stackable.value,
            onChanged: (v) => controller.stackable.value = v,
          ),
        ),
      ],
    );
  }

  Widget _submitButton(bool isEdit, String? editId) {
    return Obx(
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
          onPressed: controller.isSubmitting.value
              ? null
              : () async {
                  final success = isEdit
                      ? await controller.updatePromotion(editId!)
                      : await controller.createPromotion();
                  // SEBELUM
                  if (success) {
                    if (isEdit) {
                      Get.back();
                    } else {
                      Get.until(
                        (route) => route.settings.name == AppRoutes.promotions,
                      );
                    }
                  }
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
                  isEdit ? 'Simpan Perubahan' : 'Buat Promosi',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }

  // ===================== HELPERS =====================

  Future<void> _pickDate(BuildContext context, {required bool isFrom}) async {
    final current = isFrom
        ? controller.validFrom.value ?? DateTime.now()
        : controller.validTo.value ?? DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (ctx, child) => Theme(
        data: ThemeData(
          colorScheme: ColorScheme.light(
            primary: AppColors.primary,
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    if (isFrom) {
      controller.validFrom.value = picked;
    } else {
      controller.validTo.value = picked;
    }
  }

  // ── UI building blocks ────────────────────────────────────────────────────

  Widget _card({required String title, required Widget child}) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: Colors.grey.shade100, width: 0.5),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Colors.black54,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        child,
      ],
    ),
  );

  Widget _input(
    TextEditingController c,
    String hint, {
    TextInputType? keyboardType,
    int maxLines = 1,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: TextField(
      controller: c,
      keyboardType: keyboardType,
      maxLines: maxLines,
      textCapitalization: textCapitalization,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(fontSize: 14, color: Colors.grey.shade400),
        filled: true,
        fillColor: Colors.grey.shade100,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
    ),
  );

  Widget _datePicker({
    required BuildContext context,
    required String hint,
    required DateTime? date,
    required VoidCallback onTap,
  }) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
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
            date != null ? '${date.day}/${date.month}/${date.year}' : hint,
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
  );

  Widget _toggleTile({
    required String label,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) => Padding(
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
        Switch.adaptive(
          value: value,
          onChanged: onChanged,
          activeColor: AppColors.primary,
        ),
      ],
    ),
  );
}
