import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:senkukoadmin/constant/app_back_button.dart';
import 'package:senkukoadmin/constant/app_colors.dart';
import 'package:senkukoadmin/constant/app_textfield.dart';
import 'package:senkukoadmin/features/promotions/promotion_controller.dart';

class PromotionConditionFormPage extends StatelessWidget {
  const PromotionConditionFormPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<PromotionController>();
    final String promotionId = Get.arguments as String;

    controller.resetConditionForm();

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
                  _fieldLabel('Tipe Syarat'),
                  const SizedBox(height: 6),
                  Obx(
                    () => DropdownButtonFormField<String>(
                      value: controller.conditionType.value,
                      decoration: _inputDecoration(),
                      items: const [
                        DropdownMenuItem(
                          value: 'min_transaction_amount',
                          child: Text('Min. Total Belanja'),
                        ),
                        DropdownMenuItem(
                          value: 'min_qty',
                          child: Text('Min. Qty Item'),
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
                      onChanged: (v) => controller.conditionType.value = v!,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _fieldLabel('Operator'),
                  const SizedBox(height: 6),
                  Obx(
                    () => DropdownButtonFormField<String>(
                      value: controller.conditionOperator.value,
                      decoration: _inputDecoration(),
                      items: const [
                        DropdownMenuItem(
                          value: 'gte',
                          child: Text('>= (lebih besar atau sama)'),
                        ),
                        DropdownMenuItem(
                          value: 'lte',
                          child: Text('<= (lebih kecil atau sama)'),
                        ),
                        DropdownMenuItem(
                          value: 'eq',
                          child: Text('= (sama dengan)'),
                        ),
                        DropdownMenuItem(
                          value: 'in',
                          child: Text('in (salah satu dari)'),
                        ),
                      ],
                      onChanged: (v) => controller.conditionOperator.value = v!,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _fieldLabel('Value'),
                  const SizedBox(height: 6),
                  AppTextField(
                    hint: 'Contoh: 50000 atau member,reguler',
                    controller: controller.conditionValueC,
                  ),
                  Obx(
                    () =>
                        controller.conditionNeedsTargetId(
                          controller.conditionType.value,
                        )
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 12),
                              _fieldLabel(
                                controller.conditionType.value ==
                                        'specific_product'
                                    ? 'Product ID'
                                    : 'Category ID',
                              ),
                              const SizedBox(height: 6),
                            AppTextField(
                              hint: 'UUID',
                              controller: controller.conditionTargetIdC,
                            ),
                            ],
                          )
                        : const SizedBox(),
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
                  onPressed: controller.isSubmitting.value
                      ? null
                      : () async {
                          final ok = await controller.addCondition(promotionId);
                          if (ok) Get.back();
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

  Widget _fieldLabel(String label) => Text(
    label,
    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
  );


  InputDecoration _inputDecoration({String? hint}) => InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
    filled: true,
    fillColor: Colors.grey.shade100,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: AppColors.primary.withAlpha(80)),
    ),
  );
}
