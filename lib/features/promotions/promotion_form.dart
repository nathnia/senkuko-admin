import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:senkukoadmin/constant/app_back_button.dart';
import 'package:senkukoadmin/constant/app_colors.dart';
import 'package:senkukoadmin/constant/app_dropdown.dart';
import 'package:senkukoadmin/constant/app_textfield.dart';
import 'package:senkukoadmin/features/products/widgets/unsaved_changes_dialog.dart';
import 'package:senkukoadmin/features/promotions/promotion_controller.dart';
import 'package:senkukoadmin/routes/routes.dart';

class PromotionFormPage extends StatefulWidget {
  const PromotionFormPage({super.key});

  @override
  State<PromotionFormPage> createState() => _PromotionFormPageState();
}

class _PromotionFormPageState extends State<PromotionFormPage> {
  final controller = Get.find<PromotionController>();

  late final bool _isEdit;
  late final String? _editId;

  @override
  void initState() {
    super.initState();
    _editId = Get.arguments as String?;
    _isEdit = _editId != null;

    if (_isEdit) {
      final promo = controller.selectedPromotion.value;
      if (promo != null) controller.loadFormFromPromotion(promo);
    } else {
      controller.resetForm();
    }
  }

  Future<bool> _confirmLeave() async {
    if (!controller.isDirty.value) return true;
    return UnsavedChangesDialog.show(title: 'Promosi belum disimpan');
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
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
              if (await _confirmLeave()) Get.back();
            },
          ),
          title: Text(
            _isEdit ? 'Edit Promosi' : 'Buat Promosi',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _card(title: 'INFORMASI PROMOSI', child: _infoFields()),
              const SizedBox(height: 12),
              _card(title: 'PERIODE & BATAS', child: _periodFields()),
              const SizedBox(height: 12),
              _card(title: 'PENGATURAN', child: _settingsFields()),
              const SizedBox(height: 24),
              _submitButton(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ── Sections ──────────────────────────────────────────────────────────────

  Widget _infoFields() {
    return Column(
      children: [
        AppTextField(
          label: 'Nama Promosi',
          hint: 'cth: Promo Lebaran 2025',
          controller: controller.nameC,
        ),
        AppTextField(
          label: 'Kode Promo',
          hint: 'cth: LEBARAN25',
          controller: controller.codeC,
          textCapitalization: TextCapitalization.characters,
        ),
        _typeSelector(),
        AppTextField(
          label: 'Deskripsi',
          hint: 'Deskripsi singkat promosi (opsional)',
          controller: controller.descC,
          maxLines: 2,
        ),
      ],
    );
  }

  Widget _typeSelector() {
    final labels = {
      'discount_percent': 'Diskon %',
      'discount_fixed': 'Diskon Nominal',
      'free_item': 'Gratis Item',
    };

    return Obx(
      () => AppDropdown<String>(
        value: controller.selectedType.value.isEmpty
            ? null
            : controller.selectedType.value,
        label: 'Tipe Promosi', // ← pakai parameter yang sudah ada
        hint: 'Pilih tipe promosi',
        items: labels.entries
            .map(
              (e) =>
                  DropdownMenuItem<String>(value: e.key, child: Text(e.value)),
            )
            .toList(),
        onChanged: (val) {
          if (val != null) controller.selectedType.value = val;
        },
      ),
    );
  }

  Widget _periodFields() {
    return Column(
      children: [
        AppTextField(
          label: 'Batas Pemakaian',
          hint: 'cth: 100 (0 = unlimited)',
          controller: controller.usageLimitC,
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: Obx(
                () => _datePicker(
                  label: 'Berlaku Dari', // ← tambah
                  hint: 'Pilih tanggal',
                  date: controller.validFrom.value,
                  onTap: () => _pickDate(isFrom: true),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Obx(
                () => _datePicker(
                  label: 'Berlaku Hingga', // ← tambah
                  hint: 'Pilih tanggal',
                  date: controller.validTo.value,
                  onTap: () => _pickDate(isFrom: false),
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

  Widget _submitButton() {
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
          onPressed: controller.isSubmitting.value || !controller.isDirty.value
              ? null 
              : () async {
                  final success = _isEdit
                      ? await controller.updatePromotion(_editId!)
                      : await controller.createPromotion();
                  if (!mounted) return;
                  if (success) {
                    if (_isEdit) {
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
                  _isEdit ? 'Simpan Perubahan' : 'Buat Promosi',
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

  // ── Helpers ──────────────────────────────────────────────────────────────

  Future<void> _pickDate({required bool isFrom}) async {
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
    controller.setDate(picked, isFrom: isFrom);
  }

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

  Widget _datePicker({
    required String label, // ← tambah
    required String hint,
    required DateTime? date,
    required VoidCallback onTap,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        // ← label text, sama style AppTextField
        label,
        style: TextStyle(
          fontSize: 12,
          color: AppColors.subtext,
          fontWeight: FontWeight.w500,
        ),
      ),
      const SizedBox(height: 5),
      GestureDetector(
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
                color: AppColors.subtext,
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
      ),
    ],
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
