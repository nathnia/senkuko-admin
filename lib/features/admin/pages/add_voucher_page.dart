import 'package:flutter/material.dart';
import 'package:senkukoadmin/constant/app_colors.dart';

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
            _label("Judul Voucher"),
            _inputField("Contoh: Diskon Lebaran"),
            const SizedBox(height: 12),

            _label("Kode Voucher"),
            _inputField("Contoh: HEMAT20"),
            const SizedBox(height: 12),

            _label("Minimum Belanja"),
            _inputField("Contoh: Min. belanja 50000"),
            const SizedBox(height: 12),

            _label("Max Diskon"),
            _inputField("Contoh: Max diskon 10000"),
            const SizedBox(height: 12),

            _label("Kuota"),
            _inputField("Contoh: 100"),
            const SizedBox(height: 12),

            _label("Status"),
            _dropdownField(),
            const SizedBox(height: 20),

            _saveButton(context),
          ],
        ),
      ),
    );
  }

  // ================= LABEL =================
  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Color.fromARGB(221, 71, 71, 71),
        ),
      ),
    );
  }

  // ================= INPUT =================
  Widget _inputField(String hint) {
    return TextField(
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  // ================= DROPDOWN =================
  Widget _dropdownField() {
    return DropdownButtonFormField(
      value: "aktif",
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 4,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
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