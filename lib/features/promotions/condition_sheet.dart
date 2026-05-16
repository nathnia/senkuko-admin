import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:senkukoadmin/constant/app_back_button.dart';
import 'package:senkukoadmin/constant/app_colors.dart';
import 'package:senkukoadmin/features/promotions/promotion_controller.dart';

class PromotionConditionFormPage extends StatelessWidget {
  const PromotionConditionFormPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<PromotionController>();
    final String promotionId = Get.arguments as String;

    final conditionType = 'min_transaction_amount'.obs;
    final operator = 'gte'.obs;
    final valueCtrl = TextEditingController();
    final targetIdCtrl = TextEditingController();

    bool needsTargetId(String type) =>
        type == 'specific_product' || type == 'specific_category';

    void submit() {
      if (valueCtrl.text.isEmpty) {
        return;
      }
      if (needsTargetId(conditionType.value) && targetIdCtrl.text.isEmpty) {
        return;
      }
      controller.addCondition(promotionId, {
        'condition_type': conditionType.value,
        'operator': operator.value,
        'value': valueCtrl.text.trim(),
        'target_type':
            needsTargetId(conditionType.value) ? conditionType.value : null,
        'target_id':
            needsTargetId(conditionType.value) ? targetIdCtrl.text.trim() : null,
      });
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
                  Obx(() => DropdownButtonFormField<String>(
                        value: conditionType.value,
                        decoration: _inputDecoration(),
                        items: const [
                          DropdownMenuItem(
                              value: 'min_transaction_amount',
                              child: Text('Min. Total Belanja')),
                          DropdownMenuItem(
                              value: 'min_qty',
                              child: Text('Min. Qty Item')),
                          DropdownMenuItem(
                              value: 'specific_product',
                              child: Text('Produk Tertentu')),
                          DropdownMenuItem(
                              value: 'specific_category',
                              child: Text('Kategori Tertentu')),
                          DropdownMenuItem(
                              value: 'member_type',
                              child: Text('Tipe Member')),
                        ],
                        onChanged: (v) => conditionType.value = v!,
                      )),
                  const SizedBox(height: 14),
                  _fieldLabel('Operator'),
                  const SizedBox(height: 6),
                  Obx(() => DropdownButtonFormField<String>(
                        value: operator.value,
                        decoration: _inputDecoration(),
                        items: const [
                          DropdownMenuItem(
                              value: 'gte',
                              child: Text('>= (lebih besar atau sama)')),
                          DropdownMenuItem(
                              value: 'lte',
                              child: Text('<= (lebih kecil atau sama)')),
                          DropdownMenuItem(
                              value: 'eq', child: Text('= (sama dengan)')),
                          DropdownMenuItem(
                              value: 'in',
                              child: Text('in (salah satu dari)')),
                        ],
                        onChanged: (v) => operator.value = v!,
                      )),
                  const SizedBox(height: 14),
                  _fieldLabel('Value'),
                  const SizedBox(height: 6),
                  TextField(
                    controller: valueCtrl,
                    style: const TextStyle(fontSize: 13),
                    decoration: _inputDecoration(
                        hint: 'Contoh: 50000 atau member,reguler'),
                  ),
                  Obx(() => needsTargetId(conditionType.value)
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 14),
                            _fieldLabel(
                              conditionType.value == 'specific_product'
                                  ? 'Product ID'
                                  : 'Category ID',
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: targetIdCtrl,
                              style: const TextStyle(fontSize: 13),
                              decoration: _inputDecoration(hint: 'UUID'),
                            ),
                          ],
                        )
                      : const SizedBox()),
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
                            'Simpan Syarat',
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