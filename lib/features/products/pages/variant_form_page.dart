import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:senkukoadmin/constant/app_colors.dart';
import 'package:senkukoadmin/constant/app_dialog.dart';
import 'package:senkukoadmin/constant/app_dropdown.dart';
import 'package:senkukoadmin/constant/app_textfield.dart';
import 'package:senkukoadmin/constant/currency_formatter.dart';
import 'package:senkukoadmin/features/products/controllers/price_controller.dart';
import 'package:senkukoadmin/features/products/controllers/product_controller.dart';
import 'package:senkukoadmin/features/products/controllers/product_variant_controller.dart';
import 'package:senkukoadmin/features/products/controllers/unit_controller.dart';
import 'package:senkukoadmin/features/products/widgets/app_card.dart';
import 'package:senkukoadmin/constant/app_back_button.dart';
import 'package:senkukoadmin/features/products/widgets/save_button.dart';

class VariantFormPage extends StatelessWidget {
  VariantFormPage({super.key});

  final c = Get.find<ProductVariantController>();
  final controller = Get.find<ProductController>();
  final priceC = Get.find<PriceController>();
  final unitC = Get.find<UnitController>();

  void _handleBack({required bool isEditing, required int? index}) {
    if (isEditing) {
      c.cancelEditVariant(index!);
    } else {
      c.clearVariantForm(productC: controller);
    }
    Get.back();
  }

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments as Map<String, dynamic>?;
    final int? index = args?['index'] as int?;
    final bool isEditMode = args?['isEditMode'] as bool? ?? false;
    final bool isEditing = index != null;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        _handleBack(isEditing: isEditing, index: index);
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: AppBackButton(
            onTap: () => _handleBack(isEditing: isEditing, index: index),
          ),
          title: Text(
            isEditing ? 'Edit Varian' : 'Tambah Varian',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          centerTitle: true,
          actions: [
            AppSaveButton(
              onTap: () {
                if (isEditing) {
                  c.saveEditVariant(index);
                } else {
                  final beforeCount = isEditMode
                      ? c.editVariantsTemp.length
                      : c.variantsTemp.length;

                  c.addVariantFromForm(isEditMode: isEditMode);

                  final afterCount = isEditMode
                      ? c.editVariantsTemp.length
                      : c.variantsTemp.length;

                  if (afterCount > beforeCount) Get.back();
                }
              },
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
                    AppTextField(
                      label: 'Nama Varian',
                      hint: 'cth: Rasa Soto',
                      controller: isEditing ? c.dialogNameC : c.variantNameC,
                      onChanged: isEditing
                          ? (_) => controller.isDirty.value = true
                          : null,
                    ),
                    AppTextField(
                      label: 'Stok',
                      hint: 'cth: 100',
                      controller: isEditing ? c.dialogStockC : c.variantStockC,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: isEditing
                          ? (_) => controller.isDirty.value = true
                          : null,
                    ),
                    AppTextField(
                      label: 'Barcode',
                      hint: 'cth: 8999999004001',
                      controller: isEditing
                          ? c.dialogBarcodeC
                          : c.variantBarcodeC,
                      onChanged: isEditing
                          ? (_) => controller.isDirty.value = true
                          : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              AppCard(
                title: 'UNIT',
                child: isEditing
                    ? _unitDropdownEdit()
                    : _unitDropdownAdd(context),
              ),
              const SizedBox(height: 12),

              _priceListCard(isEditing: isEditing),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _unitDropdownEdit() {
    return Obx(
      () => AppDropdown<String>(
        value: unitC.unitList.any((u) => u.id == c.dialogUnitId.value)
            ? c.dialogUnitId.value
            : null,
        hint: 'Pilih Unit',
        showLabel: false,
        items: unitC.unitList
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
      ),
    );
  }

  Widget _unitDropdownAdd(BuildContext context) {
    return GestureDetector(
      onTap: () => _openUnitPopup(context),
      child: Obx(() {
        final selected = unitC.unitList.firstWhereOrNull(
          (u) => u.id == c.selectedUnitId.value,
        );
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  selected != null
                      ? '${selected.name} (${selected.symbol})'
                      : 'Pilih Unit',
                  style: TextStyle(
                    fontSize: 14,
                    color: selected != null
                        ? Colors.black87
                        : AppColors.subtext,
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

  void _openUnitPopup(BuildContext context) {
    final nameC = TextEditingController();
    final symbolC = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              _sheetHandle(),
              const SizedBox(height: 14),
              const Text(
                'Pilih / Tambah Unit',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: Obx(
                  () => ListView(
                    controller: scrollController,
                    children: unitC.unitList.map((u) {
                      return ListTile(
                        title: Text(
                          '${u.name} (${u.symbol})',
                          style: const TextStyle(fontSize: 14),
                        ),
                        onTap: () {
                          c.selectedUnitId.value = u.id;
                          Get.back();
                        },
                        trailing: GestureDetector(
                          onTap: () async {
                            final confirm = await AppDialog.confirm(
                              title: 'Hapus Unit',
                              content: 'Yakin mau hapus unit ini?',
                            );
                            if (confirm) await unitC.deleteUnit(u.id);
                          },
                          child: Container(
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
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const Divider(),
              AppTextField(hint: 'Nama Unit', controller: nameC),
              AppTextField(hint: 'Symbol (pcs, box, dll)', controller: symbolC),
              const SizedBox(height: 10),
              SizedBox(
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
                  onPressed: () async {
                    if (nameC.text.isEmpty || symbolC.text.isEmpty) return;
                    final newId = await unitC.createUnit(
                      nameC.text.trim(),
                      symbolC.text.trim(),
                    );
                    if (newId != null) {
                      c.selectedUnitId.value = newId;
                      Get.back();
                    }
                  },
                  child: const Text(
                    'Tambah',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _priceListCard({required bool isEditing}) {
    return AppCard(
      title: 'HARGA PER PRICE LIST',
      child: Obx(() {
        if (priceC.priceListMaster.isEmpty) {
          return Text(
            'Belum ada price list',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
          );
        }
        return Column(
          children: priceC.sortedPriceListMaster.map((pl) {
            return Obx(() {
              final priceMap = isEditing ? priceC.dialogPrices : priceC.formPrices;
              final enabled = priceMap[pl.id]?['enabled'] as bool? ?? false;
              final priceController = isEditing
                  ? priceC.dialogPriceC[pl.id]
                  : priceC.priceControllers[pl.id];

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    SizedBox(
                      width: 100,
                      child: Text(
                        pl.name,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.subtext,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        controller: priceController,
                        keyboardType: TextInputType.number,
                        enabled: enabled,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          CurrencyInputFormatter(),
                        ],
                        onChanged: isEditing
                            ? (_) => controller.isDirty.value = true
                            : null,
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
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        c.togglePrice(
                          pl.id,
                          isDialog: isEditing,
                          productC: controller,
                        );
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
      }),
    );
  }

  Widget _sheetHandle() {
    return Container(
      width: 36,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}