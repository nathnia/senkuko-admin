import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:senkukoadmin/constant/currency_formatter.dart';
import 'package:senkukoadmin/features/transactions/transaction_model.dart';

class TransactionExportService {
  /// Generate rekap penjualan (.xlsx) dari list transaksi yang lagi
  /// ditampilkan di TransactionPage (sudah kena filter tanggal/status/search),
  /// lalu buka share sheet biar admin bisa save/kirim filenya.
  static Future<void> exportRecap(List<TransactionData> transactions) async {
    final excel = Excel.createExcel();

    _buildTransactionSheet(excel, transactions);
    _buildSummarySheet(excel, transactions);

    // Sheet default bawaan package ('Sheet1') dibuang, cuma sisain 2 sheet kita
    if (excel.sheets.containsKey('Sheet1')) {
      excel.delete('Sheet1');
    }

    final bytes = excel.save();
    if (bytes == null) {
      throw Exception('Gagal generate file Excel');
    }

    final dir = await getTemporaryDirectory();
    final fileName =
        'rekap-penjualan-${DateTime.now().millisecondsSinceEpoch}.xlsx';
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes);

    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'Rekap Penjualan Senkuko',
    );
  }

  // ── Sheet 1: Transaksi ──────────────────────────────────────────────────

  static void _buildTransactionSheet(
    Excel excel,
    List<TransactionData> transactions,
  ) {
    final sheet = excel['Transaksi'];

    sheet.appendRow([
      TextCellValue('Invoice'),
      TextCellValue('Tanggal'),
      TextCellValue('Customer'),
      TextCellValue('Metode Bayar'),
      TextCellValue('Status'),
      TextCellValue('Subtotal'),
      TextCellValue('Diskon'),
      TextCellValue('Total'),
    ]);

    for (final t in transactions) {
      sheet.appendRow([
        TextCellValue(t.invoiceNumber),
        TextCellValue(DateFormatter.formatDateTime(t.transactedAt)),
        TextCellValue(t.customerName ?? 'Pelanggan umum'),
        TextCellValue(t.paymentMethodLabel),
        TextCellValue(t.statusStyle.label),
        DoubleCellValue(t.subtotal),
        DoubleCellValue(t.totalDiscount),
        DoubleCellValue(t.grandTotal),
      ]);
    }

    _autoFitColumns(sheet, columnCount: 8);
  }

  // ── Sheet 2: Ringkasan ──────────────────────────────────────────────────

  static void _buildSummarySheet(
    Excel excel,
    List<TransactionData> transactions,
  ) {
    final sheet = excel['Ringkasan'];

    // Hanya status yang dianggap revenue — konsisten sama totalRevenue
    // di TransactionController.
    final countable = transactions.where((t) => t.isCountableRevenue);
    final totalOmzet = countable.fold(0.0, (sum, t) => sum + t.grandTotal);
    final totalTransaksi = transactions.length;
    final rataRata = totalTransaksi == 0 ? 0.0 : totalOmzet / totalTransaksi;

    sheet.appendRow([
      TextCellValue('Ringkasan Penjualan'),
    ]);
    sheet.appendRow([
      TextCellValue('Dibuat pada'),
      TextCellValue(DateFormatter.formatDateTime(DateTime.now())),
    ]);
    sheet.appendRow([]);
    sheet.appendRow([
      TextCellValue('Total Transaksi'),
      IntCellValue(totalTransaksi),
    ]);
    sheet.appendRow([
      TextCellValue('Total Omzet'),
      DoubleCellValue(totalOmzet),
    ]);
    sheet.appendRow([
      TextCellValue('Rata-rata per Transaksi'),
      DoubleCellValue(rataRata),
    ]);

    _autoFitColumns(sheet, columnCount: 2);
  }

  // ── Helper ────────────────────────────────────────────────────────────

  static void _autoFitColumns(Sheet sheet, {required int columnCount}) {
    for (var i = 0; i < columnCount; i++) {
      sheet.setColumnAutoFit(i);
    }
  }
}