import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:senkukoadmin/constant/app_back_button.dart';
import 'package:senkukoadmin/constant/app_colors.dart';
import 'package:senkukoadmin/constant/app_dropdown.dart';
import 'package:senkukoadmin/constant/app_textfield.dart';
import 'package:senkukoadmin/features/products/models/product_variant_model.dart';
import 'package:senkukoadmin/features/products/widgets/variant_picker_sheet.dart';
import 'package:senkukoadmin/features/promotions/promotion_controller.dart';

class PromotionRewardFormPage extends StatefulWidget {
  const PromotionRewardFormPage({super.key});

  @override
  State<PromotionRewardFormPage> createState() =>
      _PromotionRewardFormPageState();
}

class _PromotionRewardFormPageState extends State<PromotionRewardFormPage> {
  late final PromotionController _ctrl;
  late final String _promotionId;

  VariantData? _selectedVariant;

  @override
  void initState() {
    super.initState();
    _ctrl = Get.find<PromotionController>();
    _promotionId = Get.arguments as String;
    _ctrl.resetRewardForm();
  }

  Future<void> _openVariantPicker() async {
    final picked = await VariantPickerSheet.show(context);
    if (picked == null) return;
    setState(() => _selectedVariant = picked);
    _ctrl.freeVariantIdC.text = picked.id;
  }

  void _onRewardTypeChanged(String? value) {
    if (value == null) return;
    _ctrl.rewardType.value = value;
    // Clear variant selection when switching away from free_item
    if (value != 'free_item') {
      setState(() => _selectedVariant = null);
      _ctrl.freeVariantIdC.clear();
    }
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
        title: const Text(
          'Tambah Reward',
          style: TextStyle(
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
                  Obx(
                    () => AppDropdown<String>(
                      label: 'Tipe Reward',
                      hint: 'Pilih tipe reward',
                      value: _ctrl.rewardType.value.isEmpty
                          ? null
                          : _ctrl.rewardType.value,
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
                      onChanged: _onRewardTypeChanged,
                    ),
                  ),
                  Obx(
                    () => _ctrl.rewardType.value.isEmpty
                        ? const SizedBox()
                        : _ctrl.rewardType.value != 'free_item'
                            ? _discountFields()
                            : _freeItemFields(),
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
                  onPressed: _ctrl.isSubmitting.value ||
                          !_ctrl.isRewardFormDirty.value
                      ? null
                      : () async {
                          final ok = await _ctrl.addReward(_promotionId);
                          if (ok && context.mounted) Get.back();
                        },
                  child: _ctrl.isSubmitting.value
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Simpan Reward',
                          style: TextStyle(
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

  Widget _discountFields() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Obx(
            () => AppTextField(
              label: _ctrl.rewardType.value == 'discount_percent'
                  ? 'Nilai Diskon (%)'
                  : 'Nilai Diskon (Rp)',
              hint: _ctrl.rewardType.value == 'discount_percent'
                  ? 'cth: 10 (artinya 10%)'
                  : 'cth: 10000',
              controller: _ctrl.discountValueC,
              keyboardType: TextInputType.number,
            ),
          ),
          Obx(
            () => AppDropdown<String>(
              label: 'Mode Diskon',
              hint: 'Pilih mode diskon',
              value: _ctrl.discountMode.value.isEmpty
                  ? null
                  : _ctrl.discountMode.value,
              items: const [
                DropdownMenuItem(
                  value: 'per_transaction',
                  child: Text('Per Transaksi'),
                ),
                DropdownMenuItem(
                  value: 'per_item',
                  child: Text('Per Item'),
                ),
              ],
              onChanged: (v) => _ctrl.discountMode.value = v!,
            ),
          ),
          AppTextField(
            label: 'Maks Diskon',
            hint: 'cth: 50000 (isi 0 jika tidak ada batas)',
            controller: _ctrl.maxDiscountC,
            keyboardType: TextInputType.number,
          ),
        ],
      );

  Widget _freeItemFields() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Variant picker ───────────────────────────────────────────
          _VariantPickerField(
            selectedVariant: _selectedVariant,
            onTap: _openVariantPicker,
          ),
          AppTextField(
            label: 'Jumlah Item Gratis',
            hint: 'cth: 1',
            controller: _ctrl.freeQtyC,
            keyboardType: TextInputType.number,
          ),
        ],
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

// ═══════════════════════════════════════════════════════════════
// VARIANT PICKER FIELD — matches _CategorySelector style
// ═══════════════════════════════════════════════════════════════

class _VariantPickerField extends StatelessWidget {
  final VariantData? selectedVariant;
  final VoidCallback onTap;

  const _VariantPickerField({
    required this.selectedVariant,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasValue = selectedVariant != null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Variant Produk',
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      hasValue ? selectedVariant!.name : 'Pilih variant...',
                      style: TextStyle(
                        fontSize: 14,
                        color: hasValue ? Colors.black87 : AppColors.subtext,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    Icons.arrow_drop_down_rounded,
                    color: Colors.grey.shade400,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}