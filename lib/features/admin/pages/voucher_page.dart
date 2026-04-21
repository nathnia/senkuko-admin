import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:senkukoadmin/constant/app_colors.dart';
import 'package:senkukoadmin/routes/routes.dart';

class VoucherPage extends StatelessWidget {
  const VoucherPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Voucher"),
        backgroundColor: AppColors.background,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          VoucherCard(
            title: "Diskon Lebaran",
            code: "HEMAT20",
            minBuy: "Min. belanja 50rb",
            maxDiscount: "Max diskon 10rb",
            quota: "120 tersisa",
            status: "aktif",
          ),
          VoucherCard(
            title: "Gratis Ongkir",
            code: "ONGKIRFREE",
            minBuy: "Min. belanja 30rb",
            maxDiscount: "Tanpa max",
            quota: "50 tersisa",
            status: "terjadwal",
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.toNamed(AppRoutes.addVoucher),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          "Tambah Voucher",
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}

class VoucherCard extends StatelessWidget {
  final String title;
  final String code;
  final String minBuy;
  final String maxDiscount;
  final String quota;
  final String status;

  const VoucherCard({
    super.key,
    required this.title,
    required this.code,
    required this.minBuy,
    required this.maxDiscount,
    required this.quota,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              // ================= HEADER =================
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(80),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(18),
                  ),
                ),
                child: Row(
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
                    _statusBadge(),
                  ],
                ),
              ),

              // ================= BODY =================
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(minBuy, style: const TextStyle(fontSize: 13)),
                    const SizedBox(height: 4),
                    Text(maxDiscount, style: const TextStyle(fontSize: 13)),

                    const SizedBox(height: 12),

                    _dash(),

                    const SizedBox(height: 12),

                    // KODE
                    Center(
                      child: Text(
                        code,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    _dash(),

                    const SizedBox(height: 12),

                    // FOOTER
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Kuota: $quota",
                          style: const TextStyle(fontSize: 12),
                        ),
                        Row(
                          children: const [
                            // Text(
                            //   "Edit",
                            //   style: TextStyle(
                            //     fontSize: 12,
                            //     fontWeight: FontWeight.w600,
                            //     color: Colors.blue,
                            //   ),
                            // ),
                            SizedBox(width: 8),
                            Icon(Icons.more_vert, size: 18),
                          ],
                        )
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // ================= NOTCH LEFT =================
        Positioned(
          left: -8,
          top: 80,
          child: _circleCut(),
        ),

        // ================= NOTCH RIGHT =================
        Positioned(
          right: -8,
          top: 80,
          child: _circleCut(),
        ),
      ],
    );
  }

  Widget _circleCut() {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: AppColors.background,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _dash() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final count = (constraints.maxWidth / 6).floor();

        return Row(
          children: List.generate(
            count,
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
    );
  }

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