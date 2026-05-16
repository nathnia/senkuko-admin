import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:senkukoadmin/constant/app_colors.dart';
import 'package:senkukoadmin/constant/currency_formatter.dart';
import 'package:senkukoadmin/features/products/controllers/product_controller.dart';
import 'package:senkukoadmin/features/products/controllers/product_variant_controller.dart';
import 'package:senkukoadmin/features/products/widgets/app_card.dart';
import 'package:senkukoadmin/constant/app_back_button.dart';
import 'package:senkukoadmin/features/products/widgets/save_button.dart';


class EditVariantPage extends StatelessWidget {
  EditVariantPage({super.key});

  final c = Get.find<ProductVariantController>();
  final controller = Get.find<ProductController>();

  @override
  Widget build(BuildContext context) {
    final int index = Get.arguments?['index'] ?? 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: const AppBackButton(),
        title: const Text(
          'Edit Varian',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
        actions: [
          AppSaveButton(
            onTap: () => c.saveEditVariant(index),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            AppCard(
              title: 'INFORMASI VARIAN',
              child: Column(
                children: [
                  _input(
                    controller: c.dialogNameC,
                    hint: 'Nama Varian',
                    onChanged: (_) => controller.isDirty.value = true,
                  ),
                  _input(
                    controller: c.dialogStockC,
                    hint: 'Stok',
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (_) => controller.isDirty.value = true,
                  ),
                  _input(
                    controller: c.dialogBarcodeC,
                    hint: 'Barcode (opsional)',
                    onChanged: (_) => controller.isDirty.value = true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            AppCard(
              title: 'UNIT',
              child: Obx(
                () => DropdownButtonFormField<String>(
                  value: c.unitList.any((u) => u.id == c.dialogUnitId.value)
                      ? c.dialogUnitId.value
                      : null,
                  isExpanded: true,
                  hint: Text(
                    'Pilih Unit',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
                  ),
                  items: c.unitList
                      .map(
                        (u) => DropdownMenuItem<String>(
                          value: u.id,
                          child: Text(
                            '${u.name} (${u.symbol})',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (val) {
                    if (val != null) c.dialogUnitId.value = val;
                    controller.isDirty.value = true;
                  },
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            _priceListCard(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _priceListCard() {
    return AppCard(
      title: 'HARGA PER PRICE LIST',
      child: Obx(
        () => Column(
          children: c.sortedPriceListMaster.map((pl) {
            final entry = c.dialogPrices[pl.id];
            final enabled = entry?['enabled'] as bool? ?? false;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  SizedBox(
                    width: 100,
                    child: Text(
                      pl.name,
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      onChanged: (_) => controller.isDirty.value = true,
                      controller: c.dialogPriceC[pl.id],
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        CurrencyInputFormatter(),
                      ],
                      enabled: enabled,
                      decoration: InputDecoration(
                        hintText: '0',
                        prefixText: 'Rp ',
                        filled: true,
                        fillColor: enabled ? Colors.white : Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: enabled
                                ? AppColors.primary.withAlpha(80)
                                : Colors.grey.shade200,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: AppColors.primary.withAlpha(80)),
                        ),
                        disabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => c.togglePrice(pl.id, isDialog: true),
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: enabled ? Colors.green.shade50 : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        enabled
                            ? Icons.check_circle_rounded
                            : Icons.add_circle_outline_rounded,
                        size: 20,
                        color: enabled ? Colors.green.shade500 : Colors.grey.shade400,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _input({
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    ValueChanged<String>? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(fontSize: 14, color: Colors.grey.shade400),
          filled: true,
          fillColor: Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
      ),
    );
  }
}