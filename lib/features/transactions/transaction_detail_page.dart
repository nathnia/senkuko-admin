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

        final nextStatuses = _nextStatuses(data.status, data.isCod);
        final canCancel = !data.isTerminal;

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
                              color: AppColors.title,
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
                          color: AppColors.title,
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
                                bottom: BorderSide(color: Color(0xFFE0E0E0)),
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
                                    color: AppColors.title,
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
                              color: AppColors.title,
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
                                color: AppColors.danger,
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
                        valueColor: AppColors.danger,
                      ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Divider(height: 1, color: Color(0xFFE0E0E0)),
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
              // Hanya tampil kalau ada aksi yang tersedia atau bisa dibatalkan.
              if (nextStatuses.isNotEmpty || canCancel) ...[
                const SizedBox(height: 20),

                // Primary action buttons (maju ke status berikutnya)
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
                            backgroundColor: StatusStyle.of(s).color,
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
                                  _buttonLabel(s, data.isCod),
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

                // Cancel button — tampil selama belum terminal state,
                // termasuk untuk Midtrans pending_payment (admin bisa force cancel).
                if (canCancel)
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
                          foregroundColor: AppColors.subtext,
                          side: BorderSide(color: Colors.grey.shade200),
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

  /// Menentukan tombol aksi yang tersedia berdasarkan status dan metode bayar.
  ///
  /// Flow admin:
  /// - COD pending_payment  → processing (admin konfirmasi order diterima)
  /// - Midtrans pending_payment → [] (otomatis via webhook, admin tidak bisa advance)
  /// - processing           → shipped (COD maupun Midtrans, siapkan pengiriman)
  /// - shipped              → completed (barang sudah diterima customer)
  /// - Terminal states (completed/cancelled/failed) → tidak ada tombol
  List<String> _nextStatuses(String status, bool isCod) {
    switch (status) {
      case 'pending_payment':
        // COD: admin konfirmasi pesanan diterima → processing.
        // Midtrans: status diupdate otomatis via webhook, admin tidak bisa advance.
        return isCod ? ['processing'] : [];
      case 'processing':
        // Baik COD maupun Midtrans: siapkan dan kirim pesanan.
        return ['shipped'];
      case 'shipped':
        // Konfirmasi barang sudah diterima customer.
        return ['completed'];
      default:
        // completed, cancelled, failed — terminal, tidak ada aksi.
        return [];
    }
  }

  /// Label tombol yang human-readable untuk admin.
  String _buttonLabel(String status, bool isCod) {
    switch (status) {
      case 'processing':
        return 'Proses Pesanan';
      case 'shipped':
        return isCod ? 'Kirim & Tagih COD' : 'Kirim Pesanan';
      case 'completed':
        return 'Tandai Selesai';
      default:
        return StatusStyle.of(status).label;
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
                    ? AppColors.danger
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
                  color: AppColors.title,
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
                color: isBold ? AppColors.title : Colors.grey,
                fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isBold ? FontWeight.w600 : FontWeight.w500,
                color: valueColor ?? AppColors.title,
              ),
            ),
          ],
        ),
      );
}