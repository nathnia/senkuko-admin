import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:senkukoadmin/constant/app_colors.dart';
import 'package:senkukoadmin/routes/routes.dart';

class PromoPage extends StatelessWidget {
  const PromoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Promo"),
        backgroundColor: AppColors.background,
      ),
      body: Column(
        children: [
          _tabBar(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: const [
                PromoCard(
                  title: "Diskon Lebaran",
                  desc: "Diskon 20%",
                  date: "30 April 2026",
                  status: "aktif",
                ),
                PromoCard(
                  title: "Flash Sale",
                  desc: "Diskon 50%",
                  date: "10 Mei 2026",
                  status: "terjadwal",
                ),
                PromoCard(
                  title: "Promo Tahun Baru",
                  desc: "Gratis ongkir + cashback",
                  date: "1 Januari 2026",
                  status: "selesai",
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.toNamed(AppRoutes.addPromo),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          "Tambah Promo",
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  // ================= TAB =================
  Widget _tabBar() {
    final tabs = ["Aktif", "Terjadwal", "Selesai"];

    return SizedBox(
      height: 50,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemBuilder: (_, i) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: i == 0 ? AppColors.primary : Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              tabs[i],
              style: TextStyle(
                color: i == 0 ? Colors.white : Colors.black,
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemCount: tabs.length,
      ),
    );
  }
}

class PromoCard extends StatelessWidget {
  final String title;
  final String desc;
  final String date;
  final String status;

  const PromoCard({
    super.key,
    required this.title,
    required this.desc,
    required this.date,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ================= HEADER =================
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),

              const SizedBox(width: 8),

              _statusBadge(),

              const SizedBox(width: 6),

              const Icon(Icons.more_vert, size: 18),
            ],
          ),

          const SizedBox(height: 8),

          // ================= DESC =================
          Text(
            desc,
            style: TextStyle(
              fontSize: 17,
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          // ================= DATE =================
          Row(
            children: [
              const Icon(Icons.access_time, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                "Berlaku sampai $date",
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ================= DASH SEPARATOR =================
          LayoutBuilder(
            builder: (context, constraints) {
              final dashCount = (constraints.maxWidth / 6).floor();

              return Row(
                children: List.generate(
                  dashCount,
                  (_) => Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      height: 1,
                      color: Colors.grey.shade300,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ================= STATUS =================
  Widget _statusBadge() {
    Color color;
    String text;

    switch (status) {
      case "aktif":
        color = Colors.green;
        text = "Aktif";
        break;
      case "terjadwal":
        color = Colors.orange;
        text = "Terjadwal";
        break;
      default:
        color = Colors.grey;
        text = "Selesai";
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(150),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
