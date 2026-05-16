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

    final rewardType = 'discount_percent'.obs;
    final discountMode = 'per_transaction'.obs;
    final discountValueCtrl = TextEditingController();
    final maxDiscountCtrl = TextEditingController(text: '0');
    final freeVariantIdCtrl = TextEditingController();
    final freeQtyCtrl = TextEditingController(text: '1');

    void submit() {
      if (rewardType.value == 'free_item') {
        if (freeVariantIdCtrl.text.isEmpty) return;
        controller.addReward(promotionId, {
          'reward_type': rewardType.value,
          'free_variant_id': freeVariantIdCtrl.text.trim(),
          'free_qty': int.tryParse(freeQtyCtrl.text) ?? 1,
        });
      } else {
        if (discountValueCtrl.text.isEmpty) return;
        controller.addReward(promotionId, {
          'reward_type': rewardType.value,
          'discount_value': double.tryParse(discountValueCtrl.text) ?? 0,
          'discount_mode': discountMode.value,
          'max_discount_amount':
              double.tryParse(maxDiscountCtrl.text) ?? 0,
        });
      }
    }

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
                        value: rewardType.value,
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
                        onChanged: (v) => rewardType.value = v!,
                      )),
                  const SizedBox(height: 14),
                  Obx(() => rewardType.value != 'free_item'
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _fieldLabel('Nilai Diskon'),
                            const SizedBox(height: 6),
                            TextField(
                              controller: discountValueCtrl,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(fontSize: 13),
                              decoration: _inputDecoration(
                                hint: rewardType.value == 'discount_percent'
                                    ? 'Contoh: 10 (artinya 10%)'
                                    : 'Contoh: 10000',
                              ),
                            ),
                            const SizedBox(height: 14),
                            _fieldLabel('Mode Diskon'),
                            const SizedBox(height: 6),
                            Obx(() => DropdownButtonFormField<String>(
                                  value: discountMode.value,
                                  decoration: _inputDecoration(),
                                  items: const [
                                    DropdownMenuItem(
                                        value: 'per_transaction',
                                        child: Text('Per Transaksi')),
                                    DropdownMenuItem(
                                        value: 'per_item',
                                        child: Text('Per Item')),
                                  ],
                                  onChanged: (v) =>
                                      discountMode.value = v!,
                                )),
                            const SizedBox(height: 14),
                            _fieldLabel('Maks. Diskon (0 = tidak ada batas)'),
                            const SizedBox(height: 6),
                            TextField(
                              controller: maxDiscountCtrl,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(fontSize: 13),
                              decoration:
                                  _inputDecoration(hint: '50000'),
                            ),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _fieldLabel('Variant ID (item gratis)'),
                            const SizedBox(height: 6),
                            TextField(
                              controller: freeVariantIdCtrl,
                              style: const TextStyle(fontSize: 13),
                              decoration: _inputDecoration(
                                  hint: 'UUID variant produk'),
                            ),
                            const SizedBox(height: 14),
                            _fieldLabel('Jumlah Gratis'),
                            const SizedBox(height: 6),
                            TextField(
                              controller: freeQtyCtrl,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(fontSize: 13),
                              decoration: _inputDecoration(hint: '1'),
                            ),
                          ],
                        )),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Obx(() => SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed:
                        controller.isSubmitting.value ? null : submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
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
                                fontWeight: FontWeight.w600,
                                color: Colors.white),
                          ),
                  ),
                )),
          ],
        ),
      ),
    );
  }

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

  Widget _fieldLabel(String label) => Text(
        label,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
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