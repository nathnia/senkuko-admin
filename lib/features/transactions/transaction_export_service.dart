import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:senkukoadmin/features/transactions/transaction_summary_model.dart';
import 'package:senkukoadmin/features/transactions/transaction_export_row_model.dart';

class TransactionExportService {
  /// Generate rekap penjualan (.xlsx) dari data yang sudah ditarik lengkap
  /// dari backend (`TransactionService.fetchAllExportRows` +
  /// `fetchSummary`) — bukan lagi dari list lokal yang lagi ditampilkan di
  /// halaman, jadi hasil export selalu lengkap sesuai rentang tanggal,
  /// gak kebatas apa yang lagi ke-load/ke-filter di UI.
  static Future<void> exportRecap({
    required List<TransactionExportRow> rows,
    required TransactionSummary summary,
  }) async {
    final excel = Excel.createExcel();

    _buildTransactionSheet(excel, rows);
    _buildItemSheet(excel, rows);
    _buildSummarySheet(excel, rows, summary);

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
    List<TransactionExportRow> rows,
  ) {
    final sheet = excel['Transaksi'];

    sheet.appendRow([
      TextCellValue('Invoice'),
      TextCellValue('Status'),
      TextCellValue('Jumlah Item'),
      TextCellValue('Subtotal'),
      TextCellValue('Total'),
    ]);

    for (final r in rows) {
      sheet.appendRow([
        TextCellValue(r.invoiceNumber),
        TextCellValue(r.status),
        IntCellValue(r.totalQty),
        DoubleCellValue(r.subtotal.toDouble()),
        DoubleCellValue(r.grandTotal.toDouble()),
      ]);
    }

    _autoFitColumns(sheet, columnCount: 5);
  }

  // ── Sheet 2: Item (detail per produk per transaksi) ─────────────────────

  static void _buildItemSheet(Excel excel, List<TransactionExportRow> rows) {
    final sheet = excel['Item'];

    sheet.appendRow([
      TextCellValue('Invoice'),
      TextCellValue('Produk'),
      TextCellValue('Qty'),
      TextCellValue('Harga Satuan'),
      TextCellValue('Subtotal Item'),
    ]);

    for (final r in rows) {
      for (final item in r.items) {
        sheet.appendRow([
          TextCellValue(r.invoiceNumber),
          TextCellValue(item.productName),
          IntCellValue(item.qty),
          DoubleCellValue(item.price.toDouble()),
          DoubleCellValue(item.price.toDouble() * item.qty),
        ]);
      }
    }

    _autoFitColumns(sheet, columnCount: 5);
  }

  // ── Sheet 3: Ringkasan ──────────────────────────────────────────────────

  static void _buildSummarySheet(
    Excel excel,
    List<TransactionExportRow> rows,
    TransactionSummary summary,
  ) {
    final sheet = excel['Ringkasan'];

    // Omzet dihitung dari rows yang di-export (sudah termasuk semua status
    // dalam rentang tanggal) — beda dari totalRevenue di controller yang
    // cuma ngitung status "countable". Kalau butuh omzet dengan definisi
    // yang sama, filter `rows` di controller sebelum manggil service ini.
    final totalOmzet = rows.fold<num>(0, (sum, r) => sum + r.grandTotal);
    final rataRata = rows.isEmpty ? 0.0 : totalOmzet / rows.length;

    sheet.appendRow([TextCellValue('Ringkasan Penjualan')]);
    sheet.appendRow([
      TextCellValue('Dibuat pada'),
      TextCellValue(DateTime.now().toIso8601String()),
    ]);
    sheet.appendRow([]);
    sheet.appendRow([
      TextCellValue('Total Transaksi (rentang)'),
      IntCellValue(summary.totalTransactions),
    ]);
    sheet.appendRow([
      TextCellValue('Total Item Terjual (rentang)'),
      IntCellValue(summary.totalItemsOrdered),
    ]);
    sheet.appendRow([
      TextCellValue('Total Omzet (data di-export)'),
      DoubleCellValue(totalOmzet.toDouble()),
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