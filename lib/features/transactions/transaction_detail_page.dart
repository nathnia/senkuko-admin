import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:senkukoadmin/constant/app_back_button.dart';
import 'package:senkukoadmin/constant/app_colors.dart';
import 'package:senkukoadmin/constant/app_error_state.dart';
import 'package:senkukoadmin/constant/currency_formatter.dart';
import 'package:senkukoadmin/features/transactions/transaction_controller.dart';
import 'package:senkukoadmin/features/transactions/transaction_model.dart';

class TransactionDetailPage extends StatelessWidget {
  const TransactionDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<TransactionController>();
    final String? id = Get.arguments as String?;

    if (id == null) {
      return const Scaffold(body: Center(child: Text('ID tidak ditemukan')));
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.fetchTransactionById(id);
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
              backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: AppBackButton(onTap: () => Get.back()),
        title: const Text(
          'Detail Transaksi',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
      ),
      body: Obx(() {
        if (controller.isLoadingDetail.value) {
          return const Center(child: CircularProgressIndicator());
        }
         if (controller.hasDetailError.value) {
    return AppErrorState(
      message: controller.detailErrorMessage.value,
      onRetry: () => controller.fetchTransactionById(id),
    );
  }


        final data = controller.selectedTransaction.value;
        if (data == null) {
          return const Center(child: Text('Data tidak ditemukan'));
        }

        final items = data['items'] as List? ?? [];
        final promotions = data['promotions'] as List? ?? [];

        final totalDiscount =
            double.parse((data['total_discount'] ?? '0').toString());

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Info transaksi ───────────────────────────────────────────
              _card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          data['invoice_number'] ?? '',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A1A2E),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8FAF3),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Selesai',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _infoRow(
                      'Tanggal',
                      DateFormatter.formatDateTimeRaw(
                          data['transacted_at'] ?? ''),
                    ),
                    _infoRow(
                      'Pelanggan',
                      data['customer_name'] ?? 'Pelanggan umum',
                    ),
                    _infoRow(
                      'Metode',
                      PaymentStyle.of(data['payment_method'] ?? '').label,
                    ),
                  ],
                ),
              ),

              // ── Item pembelian ───────────────────────────────────────────
              const SizedBox(height: 12),
              _sectionLabel('Item Pembelian'),
              _card(
                child: Column(
                  children: items.asMap().entries.map((entry) {
                    final item = entry.value as Map<String, dynamic>;
                    final isLast = entry.key == items.length - 1;
                    return Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        border: isLast
                            ? null
                            : const Border(
                                bottom:
                                    BorderSide(color: Color(0xFFF0F0F0))),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['variant_name'] ?? '',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF1A1A2E),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${item['price_list_name']} • ${CurrencyFormatter.format(item['unit_price'] ?? '0')} x ${item['qty']}',
                                  style: const TextStyle(
                                      fontSize: 11, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            CurrencyFormatter.format(
                                item['subtotal'] ?? '0'),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1A1A2E),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),

              // ── Promo & diskon ───────────────────────────────────────────
              if (promotions.isNotEmpty) ...[
                const SizedBox(height: 12),
                _sectionLabel('Promo & Diskon'),
                _card(
                  child: Column(
                    children: promotions.map((promo) {
                      final p = promo as Map<String, dynamic>;
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            p['promo_name'] ?? p['voucher_code'] ?? '-',
                            style: const TextStyle(
                                fontSize: 13, color: Colors.grey),
                          ),
                          Text(
                            '- ${CurrencyFormatter.format(p['discount_amount']?.toString() ?? '0')}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFFFF6B6B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ],

              // ── Ringkasan pembayaran ──────────────────────────────────────
              const SizedBox(height: 12),
              _sectionLabel('Ringkasan Pembayaran'),
              _card(
                child: Column(
                  children: [
                    _summaryRow(
                      'Subtotal',
                      CurrencyFormatter.format(data['subtotal'] ?? '0'),
                    ),
                    // pakai double yang sudah diparse — tidak ada tryParse tersebar
                    if (totalDiscount != 0)
                      _summaryRow(
                        'Diskon',
                        '- ${CurrencyFormatter.format(data['total_discount'] ?? '0')}',
                        valueColor: const Color(0xFFFF6B6B),
                      ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Divider(height: 1, color: Color(0xFFF0F0F0)),
                    ),
                    _summaryRow(
                      'Total',
                      CurrencyFormatter.format(data['grand_total'] ?? '0'),
                      isBold: true,
                      valueColor: AppColors.primary,
                    ),
                    const SizedBox(height: 8),
                    _summaryRow(
                      'Dibayar',
                      CurrencyFormatter.format(data['paid_amount'] ?? '0'),
                    ),
                    _summaryRow(
                      'Kembalian',
                      CurrencyFormatter.format(data['change_amount'] ?? '0'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        );
      }),
    );
  }

  Widget _card({required Widget child}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: child,
      );

  Widget _sectionLabel(String label) => Padding(
        padding: const EdgeInsets.only(left: 2, bottom: 8),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey,
            letterSpacing: 0.3,
          ),
        ),
      );

  Widget _infoRow(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          children: [
            SizedBox(
              width: 80,
              child: Text(label,
                  style:
                      const TextStyle(fontSize: 12, color: Colors.grey)),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1A1A2E),
              ),
            ),
          ],
        ),
      );

  Widget _summaryRow(
    String label,
    String value, {
    bool isBold = false,
    Color? valueColor,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: isBold ? const Color(0xFF1A1A2E) : Colors.grey,
                fontWeight:
                    isBold ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight:
                    isBold ? FontWeight.w600 : FontWeight.w500,
                color: valueColor ?? const Color(0xFF1A1A2E),
              ),
            ),
          ],
        ),
      );
}