import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:senkukoadmin/constant/app_colors.dart';

class OrderDetailPage extends StatelessWidget {
  const OrderDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final pesanan = Get.arguments;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Detail Pesanan"),
        backgroundColor: AppColors.primary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _cardCustomer(pesanan),
            const SizedBox(height: 12),
            _cardStatus(pesanan),
            const SizedBox(height: 12),
            _cardPermintaan(pesanan),
            const SizedBox(height: 12),
            _cardPenyesuaian(),
            const SizedBox(height: 12),
            _cardCatatan(),
            const SizedBox(height: 20),
            _tombolAksi(pesanan["status"]),
          ],
        ),
      ),
    );
  }

  // ================= CUSTOMER =================
  Widget _cardCustomer(Map pesanan) {
    return Card(
      color: AppColors.card,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "ID Pelanggan",
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 4),
            Text(
              pesanan["id"] ?? "-",
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= STATUS =================
  Widget _cardStatus(Map pesanan) {
    return Card(
      color: AppColors.card,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Text(
              "Status: ",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              pesanan["status"] ?? "-",
              style: const TextStyle(
                color: Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= PERMINTAAN =================
  Widget _cardPermintaan(Map pesanan) {
    final items = pesanan["items"] as List;

    return Card(
      color: AppColors.card,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Barang yang Dipesan",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ...items.map(
              (item) => Text(
                "• ${item["name"]} x${item["qty"]}",
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= PENYESUAIAN =================
  Widget _cardPenyesuaian() {
    return Card(
      color: AppColors.card,
      elevation: 0,
      child: const Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Penyesuaian oleh Senkuko",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.warning_amber,
                    size: 16, color: Colors.orange),
                SizedBox(width: 8),
                Text("Beras 5kg → STOK HABIS"),
              ],
            ),
            SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.check, size: 16, color: Colors.green),
                SizedBox(width: 8),
                Text("Minyak Goreng x1 (dikurangi)"),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ================= CATATAN =================
  Widget _cardCatatan() {
    return Card(
      color: AppColors.card,
      elevation: 0,
      child: const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          "Beberapa barang diubah karena stok terbatas. Mohon konfirmasi ulang.",
        ),
      ),
    );
  }

  // ================= TOMBOL AKSI =================
  Widget _tombolAksi(String status) {
    if (status == "Selesai") return const SizedBox();

    return SizedBox(
      width: double.infinity,
      child: _tombolBerdasarkanStatus(status),
    );
  }

  Widget _tombolBerdasarkanStatus(String status) {
    switch (status) {
      case "Pending":
        return _btn("Setujui Review", Colors.green);

      case "Review":
        return _btn("Minta Perubahan", Colors.orange);

      case "Confirm":
        return _btn("Dikonfirmasi Pelanggan", Colors.blue);

      case "Processing":
        return _btn("Tandai Dikirim", Colors.purple);

      case "Shipped":
        return _btn("Selesaikan Pesanan", Colors.teal);

      default:
        return const SizedBox();
    }
  }

  Widget _btn(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}