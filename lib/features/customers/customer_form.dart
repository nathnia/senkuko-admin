import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:senkukoadmin/constant/app_back_button.dart';
import 'package:senkukoadmin/constant/app_card.dart';
import 'package:senkukoadmin/constant/app_colors.dart';
import 'package:senkukoadmin/constant/app_dropdown.dart';
import 'package:senkukoadmin/constant/app_textfield.dart';
import 'package:senkukoadmin/constant/save_button.dart';
import 'package:senkukoadmin/constant/unsaved_changes_dialog.dart';
import 'package:senkukoadmin/features/customers/customer_controller.dart';
import 'package:senkukoadmin/features/customers/customer_model.dart';

enum CustomerFormMode { add, edit }

class CustomerFormPage extends StatefulWidget {
  const CustomerFormPage({super.key});

  @override
  State<CustomerFormPage> createState() => _CustomerFormPageState();
}

class _CustomerFormPageState extends State<CustomerFormPage> {
  late final CustomerController _c;
  late final CustomerFormMode _mode;
  CustomerData? _customer; // null kalau add mode

  @override
  void initState() {
    super.initState();
    _c = Get.find<CustomerController>();

    final args = Get.arguments;
    if (args is CustomerData) {
      _mode = CustomerFormMode.edit;
      _customer = args;
      _c.populateEditForm(args);
    } else {
      _mode = CustomerFormMode.add;
      _c.resetForAdd();
    }
  }

  bool get _isEdit => _mode == CustomerFormMode.edit;

  Future<bool> _onWillPop() async {
    if (!_c.isDirty.value) return true;
    return UnsavedChangesDialog.show();
  }

  Widget _stickyButton() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Obx(
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
              onPressed: _c.isSubmitting.value || !_c.isDirty.value
                  ? null
                  : _onSubmit,
              child: _c.isSubmitting.value
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
      ),
    );
  }

  Future<void> _onSubmit() async {
    final bool ok;
    if (_isEdit) {
      ok = await _c.updateCustomer(_customer!.id);
    } else {
      ok = await _c.createCustomer();
    }
    if (ok && mounted) Get.back();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) Get.back();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: AppBackButton(
            onTap: () async {
              final shouldPop = await _onWillPop();
              if (shouldPop) Get.back();
            },
          ),
          title: Text(
            _isEdit ? 'Edit Pelanggan' : 'Tambah Pelanggan',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          centerTitle: true,
          actions: _isEdit
              ? [
                  Obx(
                    () => AppSaveButton(
                      isLoading: _c.isSubmitting.value,
                      isDisabled: !_c.isDirty.value,
                      label: 'Simpan',
                      onTap: _onSubmit,
                    ),
                  ),
                ]
              : null,
        ),
        bottomNavigationBar: _isEdit ? null : _stickyButton(),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // ── Informasi Utama ───────────────────────────────────
              AppCard(
                title: 'INFORMASI UTAMA',
                child: Column(
                  children: [
                    AppTextField(
                      controller: _c.nameC,
                      label: 'Nama Pelanggan',
                      hint: 'Masukkan nama pelanggan',
                      textCapitalization: TextCapitalization.words,
                    ),
                    AppTextField(
                      controller: _c.codeC,
                      label: 'Kode Pelanggan',
                      hint: 'Contoh: CUST001',
                      textCapitalization: TextCapitalization.characters,
                    ),
                    Obx(
                      () => AppDropdown<CustomerGroup>(
                        label: 'Grup Pelanggan',
                        value: _c.customerGroup.value,
                        items: CustomerGroup.values
                            .map(
                              (g) => DropdownMenuItem(
                                value: g,
                                child: Text(g.label),
                              ),
                            )
                            .toList(),
                        onChanged: (val) {
                          if (val == null) return;
                          if (_isEdit) {
                            _c.onGroupChanged(val);
                          } else {
                            _c.customerGroup.value = val;
                          }
                        },
                        isRequired: true,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // ── Kontak ────────────────────────────────────────────
              AppCard(
                title: 'KONTAK',
                child: Column(
                  children: [
                    AppTextField(
                      controller: _c.phoneC,
                      label: 'No. Telepon',
                      hint: '08xxxxxxxxxx',
                      keyboardType: TextInputType.phone,
                    ),
                    AppTextField(
                      controller: _c.emailC,
                      label: 'Email',
                      hint: 'email@contoh.com',
                      keyboardType: TextInputType.emailAddress,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // ── Lokasi ────────────────────────────────────────────
              AppCard(
                title: 'LOKASI',
                child: Column(
                  children: [
                    AppTextField(
                      controller: _c.addressC,
                      label: 'Alamat',
                      hint: 'Jl. contoh no. 1',
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    AppTextField(
                      controller: _c.cityC,
                      label: 'Kota',
                      hint: 'Jakarta',
                      textCapitalization: TextCapitalization.words,
                    ),
                    AppTextField(
                      controller: _c.regionC,
                      label: 'Region',
                      hint: 'DKI Jakarta',
                      textCapitalization: TextCapitalization.words,
                    ),
                    AppTextField(
                      controller: _c.subregionC,
                      label: 'Subregion',
                      hint: 'Jakpus',
                      textCapitalization: TextCapitalization.words,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}