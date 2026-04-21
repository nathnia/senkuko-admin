import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:senkukoadmin/constant/app_colors.dart';
import 'package:senkukoadmin/routes/routes.dart';

class OrderPage extends StatelessWidget {
  const OrderPage({super.key});

  final orders = const [
    {
      "id": "ORD001",
      "status": "Pending",
      "items": [
        {"name": "Indomie", "qty": 2},
        {"name": "Teh Botol", "qty": 1},
      ],
    },
    {
      "id": "ORD002",
      "status": "Review",
      "items": [
        {"name": "Beras", "qty": 5},
      ],
    },
    {
      "id": "ORD003",
      "status": "Confirm",
      "items": [
        {"name": "Gula", "qty": 3},
        {"name": "Minyak", "qty": 2},
      ],
    },
    {
      "id": "ORD004",
      "status": "Processing",
      "items": [
        {"name": "Sabun", "qty": 2},
      ],
    },
    {
      "id": "ORD005",
      "status": "Shipped",
      "items": [
        {"name": "Tisu", "qty": 3},
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          title: const Text("Pesanan"),
          bottom: TabBar(
            isScrollable: true,
            tabs: [
              _tab("Pending"),
              _tab("Review (Opsional)"),
              _tab("Menunggu Konfirmasi"),
              _tab("Diproses"),
              _tab("Dikirim"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _list("Pending"),
            _list("Review"),
            _list("Confirm"),
            _list("Processing"),
            _list("Shipped"),
          ],
        ),
      ),
    );
  }

  // ================= TAB =================
  Widget _tab(String label) {
    final rawStatus = _reverseLabel(label);

    final count =
        orders.where((o) => o["status"] == rawStatus).length;

    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 6,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(20),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              "$count",
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  // ================= LIST =================
  Widget _list(String status) {
    final filtered =
        orders.where((o) => o["status"] == status).toList();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        return _card(filtered[index]);
      },
    );
  }

  // ================= CARD =================
  Widget _card(Map order) {
    final items = order["items"] as List;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Get.toNamed(
            AppRoutes.detailOrder,
            arguments: order,
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                order["id"],
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),

              const SizedBox(height: 10),

              ...items.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      Text(item["name"]),
                      Text("x${item["qty"]}"),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                "Ketuk untuk detail pesanan",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================= MAPPING LABEL =================
  String _reverseLabel(String label) {
    switch (label) {
      case "Pending":
        return "Pending";
      case "Review (Opsional)":
        return "Review";
      case "Menunggu Konfirmasi":
        return "Confirm";
      case "Diproses":
        return "Processing";
      case "Dikirim":
        return "Shipped";
      default:
        return label;
    }
  }
}