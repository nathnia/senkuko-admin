// lib/features/products/widgets/product_variant_form.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:senkukoadmin/constant/app_colors.dart';
import 'package:senkukoadmin/constant/currency_formatter.dart';
import 'package:senkukoadmin/features/products/controllers/product_controller.dart';
import 'package:senkukoadmin/features/products/controllers/product_variant_controller.dart';
import 'package:senkukoadmin/features/products/widgets/app_card.dart';

class ProductVariantForm {
  final ProductController controller;
  final variantC = Get.find<ProductVariantController>();

  ProductVariantForm(this.controller);

  // ================= VARIANT FORM =================
  Widget variantForm({bool isEditMode = false}) {
    return AppCard(
      title: 'TAMBAH VARIAN',
      actionLabel: 'Tambah',
      onAction: () => variantC.addVariantFromForm(isEditMode: isEditMode),
      child: Column(
        children: [
          _input(variantC.variantNameC, 'Nama Varian'),
          _input(variantC.variantStockC, 'Stok', isNumberOnly: true),
          _input(variantC.variantBarcodeC, 'Barcode (opsional)'),
          const SizedBox(height: 4),
          unitDropdown(),
          const SizedBox(height: 12),
          priceMatrix(),
        ],
      ),
    );
  }

  // ================= UNIT DROPDOWN =================
  Widget unitDropdown() {
    return GestureDetector(
      onTap: () => openUnitPopup(),
      child: Obx(() {
        final selected = variantC.unitList.firstWhereOrNull(
          (u) => u.id == variantC.selectedUnitId.value,
        );
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(
                Icons.straighten_outlined,
                size: 16,
                color: Colors.grey.shade500,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  selected != null
                      ? '${selected.name} (${selected.symbol})'
                      : 'Pilih Unit',
                  style: TextStyle(
                    fontSize: 14,
                    color: selected != null
                        ? Colors.black87
                        : Colors.grey.shade500,
                  ),
                ),
              ),
              Icon(Icons.arrow_drop_down_rounded, color: Colors.grey.shade400),
            ],
          ),
        );
      }),
    );
  }

  void openUnitPopup() {
    final nameC = TextEditingController();
    final symbolC = TextEditingController();
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(16),
        height: 440,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            _bottomSheetHandle(),
            const SizedBox(height: 14),
            const Text(
              'Pilih / Tambah Unit',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Obx(
                () => ListView(
                  children: variantC.unitList.map((u) {
                    return ListTile(
                      title: Text(
                        '${u.name} (${u.symbol})',
                        style: const TextStyle(fontSize: 14),
                      ),
                      onTap: () {
                        variantC.selectedUnitId.value = u.id;
                        Get.back();
                      },
                      trailing: GestureDetector(
                        onTap: () => _confirmDeleteUnit(u.id),
                        child: _deleteIconBox(),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const Divider(),
            _inputRaw(nameC, 'Nama Unit'),
            const SizedBox(height: 6),
            _inputRaw(symbolC, 'Symbol (pcs, box, dll)'),
            const SizedBox(height: 10),
            _primaryButton(
              label: 'Tambah',
              onPressed: () async {
                if (nameC.text.isEmpty || symbolC.text.isEmpty) return;
                final newId = await variantC.createUnit(
                  nameC.text.trim(),
                  symbolC.text.trim(),
                );
                if (newId != null) {
                  variantC.selectedUnitId.value = newId;
                  Get.back();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteUnit(String id) {
    Get.defaultDialog(
      title: 'Hapus Unit',
      middleText: 'Yakin mau hapus unit ini?',
      textConfirm: 'Hapus',
      textCancel: 'Batal',
      confirmTextColor: Colors.white,
      buttonColor: Colors.red,
      onConfirm: () async {
        Get.back();
        await variantC.deleteUnit(id);
      },
    );
  }

  // ================= PRICE MATRIX =================
  Widget priceMatrix() {
    return Obx(() {
      if (variantC.priceListMaster.isEmpty) {
        return Text(
          'Belum ada price list',
          style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
        );
      }
      return Column(
        children: variantC.sortedPriceListMaster.map((p) {
          return Obx(() {
            final enabled =
                variantC.formPrices[p.id]?['enabled'] as bool? ?? false;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 100,
                    child: Text(
                      p.name,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: variantC.priceControllers[p.id],
                      keyboardType: TextInputType.number,
                      enabled: enabled,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        CurrencyInputFormatter(),
                      ],
                      decoration: InputDecoration(
                        hintText: '0',
                        prefixText: 'Rp ',
                        filled: true,
                        fillColor: enabled
                            ? Colors.white
                            : Colors.grey.shade100,
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
                          borderSide: BorderSide(
                            color: AppColors.primary.withAlpha(80),
                          ),
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
                      onChanged: (_) => controller.isDirty.value = true,
                    ),
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () {
                      variantC.togglePrice(p.id);
                      controller.isDirty.value = true;
                    },
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: enabled
                            ? Colors.green.shade50
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        enabled
                            ? Icons.check_circle_rounded
                            : Icons.add_circle_outline_rounded,
                        size: 20,
                        color: enabled
                            ? Colors.green.shade500
                            : Colors.grey.shade400,
                      ),
                    ),
                  ),
                ],
              ),
            );
          });
        }).toList(),
      );
    });
  }

  // ================= PRIVATE HELPERS =================
  Widget _input(
    TextEditingController c,
    String hint, {
    bool isNumberOnly = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: c,
        onChanged: (_) => controller.isDirty.value = true,
        keyboardType: isNumberOnly ? TextInputType.number : TextInputType.text,
        inputFormatters: isNumberOnly
            ? [FilteringTextInputFormatter.digitsOnly]
            : null,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(fontSize: 14, color: Colors.grey.shade400),
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
    );
  }

  Widget _inputRaw(TextEditingController c, String hint) {
    return TextField(
      controller: c,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(fontSize: 14, color: Colors.grey.shade400),
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
    );
  }

  Widget _bottomSheetHandle() {
    return Container(
      width: 36,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _deleteIconBox() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.delete_outline_rounded,
        size: 15,
        color: Colors.red.shade400,
      ),
    );
  }

  Widget _primaryButton({
    required String label,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12),
          elevation: 0,
        ),
        onPressed: onPressed,
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
