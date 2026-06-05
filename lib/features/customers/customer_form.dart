import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:senkukoadmin/constant/app_back_button.dart';
import 'package:senkukoadmin/constant/app_card.dart';
import 'package:senkukoadmin/constant/app_colors.dart';
import 'package:senkukoadmin/constant/app_dropdown.dart';
import 'package:senkukoadmin/constant/app_textfield.dart';
import 'package:senkukoadmin/constant/unsaved_changes_dialog.dart';
import 'package:senkukoadmin/features/customers/customer_controller.dart';
import 'package:senkukoadmin/features/customers/customer_model.dart';

class AddCustomerPage extends StatelessWidget {
  const AddCustomerPage({super.key});

  Future<bool> _onWillPop(CustomerController c) async {
    if (!c.addIsDirty.value) return true;
    return UnsavedChangesDialog.show();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CustomerController>();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldPop = await _onWillPop(controller);
        if (shouldPop) Get.back();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: AppBackButton(
            onTap: () async {
              final shouldPop = await _onWillPop(controller);
              if (shouldPop) Get.back();
            },
          ),
          title: const Text(
            'Tambah Pelanggan',
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
            children: [
              // ── Informasi Utama ───────────────────────────────────────
              AppCard(
                title: 'INFORMASI UTAMA',
                child: Column(
                  children: [
                    AppTextField(
                      controller: controller.addNameC,
                      label: 'Nama Pelanggan',
                      hint: 'Masukkan nama pelanggan',
                      textCapitalization: TextCapitalization.words,
                    ),
                    AppTextField(
                      controller: controller.addCodeC,
                      label: 'Kode Pelanggan',
                      hint: 'Contoh: CUST001',
                      textCapitalization: TextCapitalization.characters,
                    ),
                    Obx(
                      () => AppDropdown<CustomerGroup>(
                        label: 'Grup Pelanggan',
                        value: controller.addCustomerGroup.value,
                        items: CustomerGroup.values
                            .map(
                              (g) => DropdownMenuItem(
                                value: g,
                                child: Text(g.label),
                              ),
                            )
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            controller.addCustomerGroup.value = val;
                          }
                        },
                        isRequired: true,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // ── Kontak ────────────────────────────────────────────────
              AppCard(
                title: 'KONTAK',
                child: Column(
                  children: [
                    AppTextField(
                      controller: controller.addPhoneC,
                      label: 'No. Telepon',
                      hint: '08xxxxxxxxxx',
                      keyboardType: TextInputType.phone,
                    ),
                    AppTextField(
                      controller: controller.addEmailC,
                      label: 'Email',
                      hint: 'email@contoh.com',
                      keyboardType: TextInputType.emailAddress,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // ── Lokasi ────────────────────────────────────────────────
              AppCard(
                title: 'LOKASI',
                child: Column(
                  children: [
                    AppTextField(
                      controller: controller.addAddressC,
                      label: 'Alamat',
                      hint: 'Jl. contoh no. 1',
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    AppTextField(
                      controller: controller.addCityC,
                      label: 'Kota',
                      hint: 'Jakarta',
                      textCapitalization: TextCapitalization.words,
                    ),
                    AppTextField(
                      controller: controller.addRegionC,
                      label: 'Region',
                      hint: 'DKI Jakarta',
                      textCapitalization: TextCapitalization.words,
                    ),
                    AppTextField(
                      controller: controller.addSubregionC,
                      label: 'Subregion',
                      hint: 'Jakpus',
                      textCapitalization: TextCapitalization.words,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Save Button ───────────────────────────────────────────
              Obx(
                () => SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade300,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: controller.isSubmitting.value ||
                            !controller.addIsDirty.value
                        ? null
                        : () async {
                            final ok = await controller.createCustomer();
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
                            'Simpan Pelanggan',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}