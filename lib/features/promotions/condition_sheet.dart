import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:senkukoadmin/constant/app_back_button.dart';
import 'package:senkukoadmin/constant/app_colors.dart';
import 'package:senkukoadmin/constant/app_dropdown.dart';
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
                  Obx(
                    () => AppDropdown<String>(
                      label: 'Tipe Syarat',
                      hint: 'Pilih tipe syarat',
                      value: controller.conditionType.value.isEmpty
                          ? null
                          : controller.conditionType.value,
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
                      onChanged: (v) => controller.conditionType.value = v!,
                    ),
                  ),
                  Obx(
                    () => AppDropdown<String>(
                      label: 'Operator',
                      hint: 'Pilih operator',
                      value: controller.conditionOperator.value.isEmpty
                          ? null
                          : controller.conditionOperator.value,
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
                          child: Text('Salah satu dari '),
                        ),
                      ],
                      onChanged: (v) => controller.conditionOperator.value = v!,
                    ),
                  ),
                  AppTextField(
                    label: 'Value',
                    hint: 'cth: 50000 atau member,reguler',
                    controller: controller.conditionValueC,
                  ),
                  Obx(
                    () =>
                        controller.conditionNeedsTargetId(
                          controller.conditionType.value,
                        )
                        ? AppTextField(
                            label:
                                controller.conditionType.value ==
                                    'specific_product'
                                ? 'ID Produk'
                                : 'ID Kategori',
                            hint:
                                controller.conditionType.value ==
                                    'specific_product'
                                ? 'cth: uuid-produk'
                                : 'cth: uuid-kategori',
                            controller: controller.conditionTargetIdC,
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
                  onPressed:
                      controller.isSubmitting.value ||
                          !controller.isConditionFormDirty.value
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
}
