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

        final nextStatuses = _nextStatuses(data.status, data.paymentMethod);

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),

              // ── Info transaksi ──────────────────────────────────────────────
              _card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            data.invoiceNumber,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1A1A2E),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: data.statusStyle.background,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            data.statusStyle.label,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: data.statusStyle.color,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _infoRow(
                      'Tanggal',
                      DateFormatter.formatDateTimeRaw(
                        data.transactedAt.toString(),
                      ),
                    ),
                    _infoRow(
                      'Pelanggan',
                      data.customerName ?? 'Pelanggan umum',
                    ),
                    _infoRow('Metode', data.paymentMethodLabel),
                    if (data.paidAt != null)
                      _infoRow(
                        'Dibayar',
                        DateFormatter.formatDateTimeRaw(
                          data.paidAt!.toString(),
                        ),
                      ),
                  ],
                ),
              ),

              // ── Alamat pengiriman ───────────────────────────────────────────
              if (data.hasAddress) ...[
                const SizedBox(height: 12),
                _sectionLabel('Alamat Pengiriman'),
                _card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data.deliveryAddress!,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF1A1A2E),
                        ),
                      ),
                      if (data.addressLine2.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          data.addressLine2,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                      if (data.deliveryNote != null &&
                          data.deliveryNote!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.info_outline,
                              size: 12,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                data.deliveryNote!,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],

              // ── Item pembelian ──────────────────────────────────────────────
              const SizedBox(height: 12),
              _sectionLabel('Item Pembelian'),
              _card(
                child: Column(
                  children: data.items.asMap().entries.map((entry) {
                    final item = entry.value;
                    final isLast = entry.key == data.items.length - 1;
                    return Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        border: isLast
                            ? null
                            : const Border(
                                bottom: BorderSide(color: Color(0xFFF0F0F0)),
                              ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.variantName,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF1A1A2E),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${item.priceListName} • ${item.formattedUnitPrice} x ${item.qty}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            item.formattedSubtotal,
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

              // ── Promo & diskon ──────────────────────────────────────────────
              if (data.promotions.isNotEmpty) ...[
                const SizedBox(height: 12),
                _sectionLabel('Promo & Diskon'),
                _card(
                  child: Column(
                    children: data.promotions.map((promo) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                promo.displayLabel,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                            Text(
                              '- ${promo.formattedDiscount}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFFFF6B6B),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],

              // ── Ringkasan pembayaran ────────────────────────────────────────
              const SizedBox(height: 12),
              _sectionLabel('Ringkasan Pembayaran'),
              _card(
                child: Column(
                  children: [
                    _summaryRow('Subtotal', data.formattedSubtotal),
                    if (data.totalDiscount != 0)
                      _summaryRow(
                        'Diskon',
                        '- ${data.formattedTotalDiscount}',
                        valueColor: const Color(0xFFFF6B6B),
                      ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Divider(height: 1, color: Color(0xFFF0F0F0)),
                    ),
                    _summaryRow(
                      'Total',
                      data.formattedGrandTotal,
                      isBold: true,
                      valueColor: AppColors.primary,
                    ),
                    const SizedBox(height: 8),
                    _summaryRow('Dibayar', data.formattedPaidAmount),
                    _summaryRow('Kembalian', data.formattedChangeAmount),
                  ],
                ),
              ),

              // ── Tombol aksi admin ───────────────────────────────────────────
              if (nextStatuses.isNotEmpty) ...[
                const SizedBox(height: 20),
                ...nextStatuses.map(
                  (s) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Obx(
                      () => SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: controller.isUpdatingStatus.value
                              ? null
                              : () => _confirmStatusUpdate(
                                    context,
                                    controller,
                                    id,
                                    s,
                                  ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _buttonColor(s),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: controller.isUpdatingStatus.value
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  _buttonLabel(s),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
                // Tombol batalkan — tampil selama belum terminal state
                if (!['completed', 'cancelled', 'failed']
                    .contains(data.status))
                  Obx(
                    () => SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: controller.isUpdatingStatus.value
                            ? null
                            : () => _confirmStatusUpdate(
                                  context,
                                  controller,
                                  id,
                                  'cancelled',
                                ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF6B7280),
                          side: const BorderSide(color: Color(0xFFE5E7EB)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Batalkan Transaksi',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ],
          ),
        );
      }),
    );
  }

  // ── Status helpers ──────────────────────────────────────────────────────────

  List<String> _nextStatuses(String status, String paymentMethod) {
    final isCod = paymentMethod == 'cod';
    switch (status) {
      case 'pending_payment':
        // COD: admin manual → processing. Midtrans: otomatis via webhook, tidak ada tombol.
        return isCod ? ['processing'] : [];
      case 'processing':
        // COD: konfirmasi bayar cash. Midtrans: shipped.
        return isCod ? ['paid'] : ['shipped'];
      case 'shipped':
        return ['completed'];
      default:
        return [];
    }
  }

  String _buttonLabel(String status) {
    switch (status) {
      case 'processing':
        return 'Proses & Kirim';
      case 'paid':
        return 'Konfirmasi Pembayaran COD';
      case 'shipped':
        return 'Tandai Sedang Dikirim';
      case 'completed':
        return 'Tandai Selesai';
      default:
        return status;
    }
  }

  Color _buttonColor(String status) {
    switch (status) {
      case 'shipped':
        return const Color(0xFF8B5CF6);
      default:
        return AppColors.primary;
    }
  }

  Future<void> _confirmStatusUpdate(
    BuildContext context,
    TransactionController controller,
    String id,
    String newStatus,
  ) async {
    final label = newStatus == 'cancelled'
        ? 'membatalkan transaksi ini'
        : 'mengubah status menjadi "${StatusStyle.of(newStatus).label}"';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Konfirmasi',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Apakah kamu yakin ingin $label?',
          style: const TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Ya, lanjutkan',
              style: TextStyle(
                color: newStatus == 'cancelled'
                    ? const Color(0xFFEF4444)
                    : AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await controller.updateTransactionStatus(id, newStatus);
    }
  }

  // ── UI helpers ──────────────────────────────────────────────────────────────

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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 80,
              child: Text(
                label,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1A1A2E),
                ),
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
                fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isBold ? FontWeight.w600 : FontWeight.w500,
                color: valueColor ?? const Color(0xFF1A1A2E),
              ),
            ),
          ],
        ),
      );
}