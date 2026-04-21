import 'package:flutter/material.dart';
import 'package:senkukoadmin/constant/app_colors.dart';

class AddPromoPage extends StatelessWidget {
  const AddPromoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Tambah Promo"),
        backgroundColor: AppColors.background,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _label("Judul Promo"),
            _inputField("Contoh: Diskon Lebaran"),
            const SizedBox(height: 12),

            _label("Jumlah Promo"),
            _inputField("Contoh: 20%"),
            const SizedBox(height: 12),

            _label("Produk yang diberi Promo"),
            _inputField("Contoh: Indomie Goreng, Indomie Kuah"),
            const SizedBox(height: 12),

            _label("Periode"),
            _inputField("Contoh: 23/7/90"),
            const SizedBox(height: 12),

            _label("Status"),
            _dropdownField(),
            const SizedBox(height: 20),

            _saveButton(),
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
  Widget _saveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {},
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          "Simpan Promo",
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}