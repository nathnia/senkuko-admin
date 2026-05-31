import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:senkukoadmin/constant/app_back_button.dart';
import 'package:senkukoadmin/constant/app_colors.dart';
import 'package:senkukoadmin/constant/app_dropdown.dart';
import 'package:senkukoadmin/constant/app_textfield.dart';
import 'package:senkukoadmin/features/products/models/category_model.dart';
import 'package:senkukoadmin/features/products/models/product_model.dart';
import 'package:senkukoadmin/features/products/widgets/category_picker_sheet.dart';
import 'package:senkukoadmin/features/products/widgets/product_picker_sheet.dart';
import 'package:senkukoadmin/features/promotions/promotion_controller.dart';

class PromotionConditionFormPage extends StatefulWidget {
  const PromotionConditionFormPage({super.key});

  @override
  State<PromotionConditionFormPage> createState() =>
      _PromotionConditionFormPageState();
}

class _PromotionConditionFormPageState
    extends State<PromotionConditionFormPage> {
  late final PromotionController _ctrl;
  late final String _promotionId;

  ProductData? _selectedProduct;
  CategoryData? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _ctrl = Get.find<PromotionController>();
    _promotionId = Get.arguments as String;
    _ctrl.resetConditionForm();
  }

  Future<void> _openProductPicker() async {
    final picked = await ProductPickerSheet.show(context);
    if (picked == null) return;
    setState(() => _selectedProduct = picked);
    _ctrl.conditionTargetIdC.text = picked.id;
  }

  Future<void> _openCategoryPicker() async {
    final picked = await CategoryPickerSheet.show(context);
    if (picked == null) return;
    setState(() => _selectedCategory = picked);
    _ctrl.conditionTargetIdC.text = picked.id;
  }

  void _onConditionTypeChanged(String? value) {
    if (value == null) return;
    _ctrl.conditionType.value = value;
    setState(() {
      _selectedProduct = null;
      _selectedCategory = null;
    });
    _ctrl.conditionTargetIdC.clear();
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
          'Tambah Syarat',
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
                      label: 'Tipe Syarat',
                      hint: 'Pilih tipe syarat',
                      value: _ctrl.conditionType.value.isEmpty
                          ? null
                          : _ctrl.conditionType.value,
                      items: const [
                        DropdownMenuItem(
                          value: 'min_transaction_amount',
                          child: Text('Min. Total Belanja'),
                        ),
                        DropdownMenuItem(
                          value: 'min_qty',
                          child: Text('Min. Jumlah Item'),
                        ),
                        DropdownMenuItem(
                          value: 'specific_product',
                          child: Text('Produk Tertentu'),
                        ),
                        DropdownMenuItem(
                          value: 'specific_category',
                          child: Text('Kategori Tertentu'),
                        ),
                        DropdownMenuItem(
                          value: 'member_type',
                          child: Text('Tipe Member'),
                        ),
                      ],
                      onChanged: _onConditionTypeChanged,
                    ),
                  ),
                  Obx(
                    () => AppDropdown<String>(
                      label: 'Operator',
                      hint: 'Pilih operator',
                      value: _ctrl.conditionOperator.value.isEmpty
                          ? null
                          : _ctrl.conditionOperator.value,
                      items: const [
                        DropdownMenuItem(
                          value: 'gte',
                          child: Text('Lebih besar atau sama dengan'),
                        ),
                        DropdownMenuItem(
                          value: 'lte',
                          child: Text('Lebih kecil atau sama dengan'),
                        ),
                        DropdownMenuItem(
                          value: 'eq',
                          child: Text('Sama dengan'),
                        ),
                        DropdownMenuItem(
                          value: 'in',
                          child: Text('Salah satu dari'),
                        ),
                      ],
                      onChanged: (v) => _ctrl.conditionOperator.value = v!,
                    ),
                  ),
                  AppTextField(
                    label: 'Value',
                    hint: 'cth: 50000 atau member,reguler',
                    controller: _ctrl.conditionValueC,
                  ),
                  Obx(() {
                    final type = _ctrl.conditionType.value;
                    if (!_ctrl.conditionNeedsTargetId(type)) {
                      return const SizedBox.shrink();
                    }
                    return type == 'specific_product'
                        ? _TargetPickerField(
                            label: 'Produk',
                            hint: 'Pilih produk...',
                            displayValue: _selectedProduct?.name,
                            onTap: _openProductPicker,
                          )
                        : _TargetPickerField(
                            label: 'Kategori',
                            hint: 'Pilih kategori...',
                            displayValue: _selectedCategory?.parentName != null
                                ? '${_selectedCategory!.parentName} › ${_selectedCategory!.name}'
                                : _selectedCategory?.name,
                            onTap: _openCategoryPicker,
                          );
                  }),
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
                          !_ctrl.isConditionFormDirty.value
                      ? null
                      : () async {
                          final ok = await _ctrl.addCondition(_promotionId);
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
                          'Simpan Syarat',
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
// TARGET PICKER FIELD — matches _CategorySelector style
// ═══════════════════════════════════════════════════════════════

class _TargetPickerField extends StatelessWidget {
  final String label;
  final String hint;
  final String? displayValue;
  final VoidCallback onTap;

  const _TargetPickerField({
    required this.label,
    required this.hint,
    required this.displayValue,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasValue = displayValue != null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
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
                      hasValue ? displayValue! : hint,
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