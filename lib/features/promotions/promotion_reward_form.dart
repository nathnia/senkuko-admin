import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:senkukoadmin/constant/app_back_button.dart';
import 'package:senkukoadmin/constant/app_colors.dart';
import 'package:senkukoadmin/constant/app_dropdown.dart';
import 'package:senkukoadmin/constant/app_textfield.dart';
import 'package:senkukoadmin/features/promotions/promotion_controller.dart';

class PromotionRewardFormPage extends StatelessWidget {
  const PromotionRewardFormPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<PromotionController>();
    final String promotionId = Get.arguments as String;

    controller.resetRewardForm();

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
                      value: controller.rewardType.value.isEmpty
                          ? null
                          : controller.rewardType.value,
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
                      onChanged: (v) => controller.rewardType.value = v!,
                    ),
                  ),
                  Obx(
                    () => controller.rewardType.value.isEmpty
                        ? const SizedBox()
                        : controller.rewardType.value != 'free_item'
                            ? _discountFields(controller)
                            : _freeItemFields(controller),
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
                          final ok = await controller.addReward(promotionId);
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

  Widget _discountFields(PromotionController controller) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Obx(
            () => AppTextField(
              hint: controller.rewardType.value == 'discount_percent'
                  ? 'Contoh: 10 (artinya 10%)'
                  : 'Contoh: 10000',
              controller: controller.discountValueC,
              keyboardType: TextInputType.number,
            ),
          ),
          Obx(
            () => AppDropdown<String>(
              label: 'Mode Diskon',
              hint: 'Pilih mode diskon',
              value: controller.discountMode.value.isEmpty
                  ? null
                  : controller.discountMode.value,
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
              onChanged: (v) => controller.discountMode.value = v!,
            ),
          ),
          AppTextField(
            hint: 'Maks diskon, isi 0 jika tidak ada batas',
            controller: controller.maxDiscountC,
            keyboardType: TextInputType.number,
          ),
        ],
      );

  Widget _freeItemFields(PromotionController controller) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppTextField(
            hint: 'UUID variant produk',
            controller: controller.freeVariantIdC,
          ),
          AppTextField(
            hint: 'Jumlah item gratis, contoh: 1',
            controller: controller.freeQtyC,
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