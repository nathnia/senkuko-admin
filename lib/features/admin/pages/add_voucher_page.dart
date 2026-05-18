import 'package:flutter/material.dart';
import 'package:senkukoadmin/constant/app_colors.dart';
import 'package:senkukoadmin/constant/app_dropdown.dart';
import 'package:senkukoadmin/constant/app_textfield.dart';

class AddVoucherPage extends StatelessWidget {
  const AddVoucherPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Tambah Voucher"),
        backgroundColor: AppColors.background,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppTextField(hint: "Contoh: Diskon Lebaran"),
            const SizedBox(height: 12),

            AppTextField(hint: "Contoh: HEMAT20"),
            const SizedBox(height: 12),

            AppTextField(hint: "Contoh: Min. belanja 50000"),
            const SizedBox(height: 12),

            AppTextField(hint: "Contoh: Max diskon 10000"),
            const SizedBox(height: 12),

            AppTextField(hint: "Contoh: 100"),
            const SizedBox(height: 12),

            _dropdownField(),
            const SizedBox(height: 20),

            _saveButton(context),
          ],
        ),
      ),
    );
  }

  // ================= DROPDOWN =================
  Widget _dropdownField() {
    return AppDropdown<String>(
      value: "aktif",
      items: const [
        DropdownMenuItem(value: "aktif", child: Text("Aktif")),
        DropdownMenuItem(value: "terjadwal", child: Text("Terjadwal")),
        DropdownMenuItem(value: "selesai", child: Text("Selesai")),
      ],
      onChanged: (value) {},
    );
  }

  // ================= SAVE =================
  Widget _saveButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          Navigator.pop(context); // balik aja dulu
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          "Simpan Voucher",
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
