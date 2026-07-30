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

enum CustomerFormMode { add, edit }

class CustomerFormPage extends StatefulWidget {
  const CustomerFormPage({super.key});

  @override
  State<CustomerFormPage> createState() => _CustomerFormPageState();
}

class _CustomerFormPageState extends State<CustomerFormPage> {
  late final CustomerController _c;
  late final CustomerFormMode _mode;
  CustomerData? _customer;

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
      _c.resetForAdd(); // auto-generate kode di sini
    }
  }

  bool get _isEdit => _mode == CustomerFormMode.edit;

  Future<bool> _onWillPop() async {
    if (!_c.isDirty.value) return true;
    return UnsavedChangesDialog.show();
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
        ),
        bottomNavigationBar: _StickyButton(c: _c, isEdit: _isEdit, onSubmit: _onSubmit),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // ── Informasi Utama ──────────────────────────────────
              AppCard(
                title: 'INFORMASI UTAMA',
                child: Column(
                  children: [
                    AppTextField(
                      controller: _c.nameC,
                      label: 'Nama Pelanggan',
                      hint: 'Masukkan nama pelanggan',
                      textCapitalization: TextCapitalization.words,
                      isRequired: true,
                    ),

                    // Kode customer — add mode punya tombol refresh untuk
                    // generate ulang, edit mode field biasa
                    if (_isEdit)
                      AppTextField(
                        controller: _c.codeC,
                        label: 'Kode Pelanggan',
                        hint: 'Contoh: CUST-A3X9B2',
                        textCapitalization: TextCapitalization.characters,
                        isRequired: true,
                      )
                    else
                      _CodeFieldWithRefresh(c: _c),

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
                      isRequired: true,
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
                      isRequired: true,
                    ),
                    AppTextField(
                      controller: _c.cityC,
                      label: 'Kota',
                      hint: 'Jakarta',
                      textCapitalization: TextCapitalization.words,
                      isRequired: true,
                    ),
                    AppTextField(
                      controller: _c.regionC,
                      label: 'Provinsi',
                      hint: 'DKI Jakarta',
                      textCapitalization: TextCapitalization.words,
                    ),
                    AppTextField(
                      controller: _c.subregionC,
                      label: 'Kecamatan',
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

// ── Kode field dengan tombol refresh (add mode only) ─────────────────────────

class _CodeFieldWithRefresh extends StatelessWidget {
  final CustomerController c;
  const _CodeFieldWithRefresh({required this.c});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: AppTextField(
            controller: c.codeC,
            label: 'Kode Pelanggan',
            hint: 'CUST-XXXXXX',
            textCapitalization: TextCapitalization.characters,
            isRequired: true,
          ),
        ),
        const SizedBox(width: 8),
        // Tombol generate ulang — muncul hanya di add mode
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Tooltip(
            message: 'Generate kode baru',
            child: InkWell(
              onTap: c.regenerateCode,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.successBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.refresh_rounded,
                  size: 18,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Sticky submit button ──────────────────────────────────────────────────────

class _StickyButton extends StatelessWidget {
  final CustomerController c;
  final bool isEdit;
  final VoidCallback onSubmit;

  const _StickyButton({
    required this.c,
    required this.isEdit,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
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
              onPressed:
                  c.isSubmitting.value || !c.isDirty.value ? null : onSubmit,
              child: c.isSubmitting.value
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      isEdit ? 'Simpan Perubahan' : 'Simpan Pelanggan',
                      style: const TextStyle(
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
}