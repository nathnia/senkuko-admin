import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:senkukoadmin/constant/app_back_button.dart';
import 'package:senkukoadmin/constant/app_colors.dart';
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
                  _fieldLabel('Tipe Reward'),
                  const SizedBox(height: 6),
                  Obx(() => DropdownButtonFormField<String>(
                        value: controller.rewardType.value,
                        decoration: _inputDecoration(),
                        items: const [
                          DropdownMenuItem(
                              value: 'discount_percent',
                              child: Text('Diskon %')),
                          DropdownMenuItem(
                              value: 'discount_fixed',
                              child: Text('Diskon Nominal')),
                          DropdownMenuItem(
                              value: 'free_item',
                              child: Text('Gratis Item')),
                        ],
                        onChanged: (v) => controller.rewardType.value = v!,
                      )),
                  const SizedBox(height: 12),
                  Obx(() => controller.rewardType.value != 'free_item'
                      ? _discountFields(controller)
                      : _freeItemFields(controller)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Obx(() => SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
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
                                color: Colors.white, strokeWidth: 2),
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
                )),
          ],
        ),
      ),
    );
  }

  Widget _discountFields(PromotionController controller) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _fieldLabel('Nilai Diskon'),
          const SizedBox(height: 6),
          Obx(() => _textField(
                controller.discountValueC,
                hint: controller.rewardType.value == 'discount_percent'
                    ? 'Contoh: 10 (artinya 10%)'
                    : 'Contoh: 10000',
                keyboardType: TextInputType.number,
              )),
          const SizedBox(height: 12),
          _fieldLabel('Mode Diskon'),
          const SizedBox(height: 6),
          Obx(() => DropdownButtonFormField<String>(
                value: controller.discountMode.value,
                decoration: _inputDecoration(),
                items: const [
                  DropdownMenuItem(
                      value: 'per_transaction', child: Text('Per Transaksi')),
                  DropdownMenuItem(
                      value: 'per_item', child: Text('Per Item')),
                ],
                onChanged: (v) => controller.discountMode.value = v!,
              )),
          const SizedBox(height: 12),
          _fieldLabel('Maks. Diskon (0 = tidak ada batas)'),
          const SizedBox(height: 6),
          _textField(controller.maxDiscountC,
              hint: '50000', keyboardType: TextInputType.number),
        ],
      );

  Widget _freeItemFields(PromotionController controller) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _fieldLabel('Variant ID (item gratis)'),
          const SizedBox(height: 6),
          _textField(controller.freeVariantIdC, hint: 'UUID variant produk'),
          const SizedBox(height: 12),
          _fieldLabel('Jumlah Gratis'),
          const SizedBox(height: 6),
          _textField(controller.freeQtyC,
              hint: '1', keyboardType: TextInputType.number),
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

  Widget _fieldLabel(String label) => Text(
        label,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
      );

  Widget _textField(
    TextEditingController c, {
    String? hint,
    TextInputType? keyboardType,
  }) =>
      TextField(
        controller: c,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 13),
        decoration: _inputDecoration(hint: hint),
      );

  InputDecoration _inputDecoration({String? hint}) => InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
        filled: true,
        fillColor: Colors.grey.shade100,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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