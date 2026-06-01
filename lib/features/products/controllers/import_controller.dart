// FILE: lib/features/products/controllers/import_controller.dart
//
// Tanggung jawab:
//   1. Generate & download template Excel
//   2. Pick file dari device
//   3. Parse + validasi baris (di isolate)
//   4. Preview hasil parse ke UI
//   5. Submit baris valid ke backend (create product + variant + price)

import 'dart:convert';
import 'dart:io';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart'; // tambahkan: file_picker: ^8.1.2 di pubspec.yaml
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:senkukoadmin/features/products/controllers/category_controller.dart';
import 'package:senkukoadmin/features/products/controllers/price_controller.dart';
import 'package:senkukoadmin/features/products/controllers/product_controller.dart';
import 'package:senkukoadmin/features/products/controllers/product_variant_controller.dart';
import 'package:senkukoadmin/features/products/controllers/unit_controller.dart';
import 'package:senkukoadmin/features/products/product_service.dart';

// ── Status satu baris hasil parse ────────────────────────────────────────────
enum ImportRowStatus { valid, error, imported, skipped }

// ── Satu baris yang sudah diparse dari Excel ──────────────────────────────────
class ImportRow {
  final int rowIndex;
  final String productName;
  final String skuCode;
  final String categoryName;
  final String variantName;
  final String unitName;
  final int stockQty;
  final Map<String, double> prices; // key: price list name (e.g. "Normal")
  final List<String> errors;
  ImportRowStatus status;

  ImportRow({
    required this.rowIndex,
    required this.productName,
    required this.skuCode,
    required this.categoryName,
    required this.variantName,
    required this.unitName,
    required this.stockQty,
    required this.prices,
    required this.errors,
    this.status = ImportRowStatus.valid,
  });

  bool get isValid => errors.isEmpty;
  String get displayTitle => '$productName — $variantName';
  String get displaySubtitle => 'SKU: $skuCode · Stok: $stockQty · $unitName';
}

// ── Payload untuk isolate (plain Dart) ───────────────────────────────────────
class _ParsePayload {
  final List<int> bytes;
  final List<String> priceListNames;
  final List<String> validUnitNames;
  final List<String> existingSkus;

  const _ParsePayload({
    required this.bytes,
    required this.priceListNames,
    required this.validUnitNames,
    required this.existingSkus,
  });
}

class _ParseResult {
  final List<ImportRow> rows;
  final List<String> priceListNames;
  const _ParseResult({required this.rows, required this.priceListNames});
}

// ─────────────────────────────────────────────────────────────────────────────

class ImportController extends GetxController {
  ProductController get _productC => Get.find<ProductController>();
  CategoryController get _categoryC => Get.find<CategoryController>();
  PriceController get _priceC => Get.find<PriceController>();
  UnitController get _unitC => Get.find<UnitController>();
  ProductVariantController get _variantC =>
      Get.find<ProductVariantController>();

  // ── State ─────────────────────────────────────────────────────────────────
  final isParsing = false.obs;
  final isSubmitting = false.obs;
  final isDownloadingTemplate = false.obs;
  final importRows = <ImportRow>[].obs;
  final submitProgress = 0.obs;
  final submitLog = <String>[].obs;
  final parsedPriceListNames = <String>[].obs;

  // ── Derived ───────────────────────────────────────────────────────────────
  List<ImportRow> get validRows =>
      importRows.where((r) => r.status == ImportRowStatus.valid).toList();
  List<ImportRow> get errorRows =>
      importRows.where((r) => r.errors.isNotEmpty).toList();
  int get importedCount =>
      importRows.where((r) => r.status == ImportRowStatus.imported).length;
  bool get hasData => importRows.isNotEmpty;
  bool get canSubmit => validRows.isNotEmpty && !isSubmitting.value;

  // ─────────────────────────────────────────────────────────────────────────
  // 1. DOWNLOAD TEMPLATE
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> downloadTemplate() async {
    if (isDownloadingTemplate.value) return;
    isDownloadingTemplate.value = true;

    try {
      final priceListNames =
          _priceC.sortedPriceListMaster.map((pl) => pl.name).toList();
      final bytes = await compute(_buildTemplateBytes, priceListNames);

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/template_import_produk.xlsx');
      await file.writeAsBytes(bytes);

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Template Import Produk',
      );
    } catch (e) {
      Get.snackbar('Gagal', 'Tidak bisa membuat template: $e');
    } finally {
      isDownloadingTemplate.value = false;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 2. PICK & PARSE FILE
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> pickAndParseFile() async {
    if (isParsing.value) return;

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;
    final bytes = result.files.first.bytes;
    if (bytes == null) {
      Get.snackbar('Error', 'Tidak bisa membaca file');
      return;
    }

    isParsing.value = true;
    importRows.clear();
    submitLog.clear();
    submitProgress.value = 0;

    try {
      final payload = _ParsePayload(
        bytes: bytes,
        priceListNames:
            _priceC.sortedPriceListMaster.map((pl) => pl.name).toList(),
        validUnitNames:
            _unitC.unitList.map((u) => u.name.toLowerCase()).toList(),
        existingSkus:
            _productC.productList.map((p) => p.skuCode.toLowerCase()).toList(),
      );

      final parsed = await compute(_parseExcelBytes, payload);
      importRows.assignAll(parsed.rows);
      parsedPriceListNames.assignAll(parsed.priceListNames);
    } catch (e) {
      Get.snackbar('Parse Gagal', 'Format file tidak dikenali: $e');
    } finally {
      isParsing.value = false;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 3. SUBMIT VALID ROWS
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> submitImport() async {
    if (!canSubmit) return;
    isSubmitting.value = true;
    submitProgress.value = 0;
    submitLog.clear();

    // Group by SKU — satu SKU = satu produk + N variants
    final grouped = <String, List<ImportRow>>{};
    for (final row in validRows) {
      grouped.putIfAbsent(row.skuCode, () => []).add(row);
    }

    final total = grouped.length;
    int done = 0;

    for (final entry in grouped.entries) {
      final sku = entry.key;
      final rows = entry.value;
      final firstRow = rows.first;

      try {
        // ── Resolve atau create kategori ──────────────────────────────────
        String? categoryId = _resolveCategoryId(firstRow.categoryName);
        if (categoryId == null && firstRow.categoryName.isNotEmpty) {
          categoryId = await _categoryC.createCategory(firstRow.categoryName);
        }

        // ── Create produk ─────────────────────────────────────────────────
        final productRes = await ProductService.createProduct(
          name: firstRow.productName,
          skuCode: sku,
          description: '',
          barcode: '',
          categoryId: categoryId,
        );

        if (productRes.statusCode != 201) {
          _markRowsSkipped(rows);
          submitLog.add('❌ $sku "${firstRow.productName}": gagal buat produk');
          done++;
          submitProgress.value = ((done / total) * 100).round();
          continue;
        }

        final newProductId =
            json.decode(productRes.body)['data']['id']?.toString() ?? '';

        if (newProductId.isEmpty) {
          _markRowsSkipped(rows);
          submitLog.add('❌ $sku: product ID kosong dari server');
          done++;
          submitProgress.value = ((done / total) * 100).round();
          continue;
        }

        // ── Create variant + prices ───────────────────────────────────────
        final priceListMap = {
          for (final pl in _priceC.priceListMaster) pl.name: pl.id,
        };

        int variantOk = 0;
        for (final row in rows) {
          final unitId = _resolveUnitId(row.unitName);
          if (unitId == null) {
            row.status = ImportRowStatus.skipped;
            submitLog.add(
              '  ⚠️  "${row.variantName}": unit "${row.unitName}" tidak ditemukan',
            );
            continue;
          }

          final variantRes = await ProductService.createVariant(
            productId: newProductId,
            unitId: unitId,
            name: row.variantName,
            stock: row.stockQty,
            isBaseUnit: variantOk == 0,
          );

          if (variantRes.statusCode != 201) {
            row.status = ImportRowStatus.skipped;
            submitLog.add(
              '  ⚠️  "${row.variantName}": gagal buat variant (${variantRes.statusCode})',
            );
            continue;
          }

          final newVariantId =
              json.decode(variantRes.body)['data']['id']?.toString() ?? '';

          // Buat semua harga secara parallel
          await Future.wait(
            row.prices.entries
                .where(
                  (e) => e.value > 0 && priceListMap.containsKey(e.key),
                )
                .map(
                  (e) => ProductService.createPrice(
                    variantId: newVariantId,
                    priceListId: priceListMap[e.key]!,
                    price: e.value,
                  ),
                ),
          );

          row.status = ImportRowStatus.imported;
          variantOk++;
        }

        submitLog.add(
          '✅ "$sku" "${firstRow.productName}": $variantOk/${rows.length} variant',
        );
      } catch (e) {
        _markRowsSkipped(rows);
        submitLog.add('❌ $sku: exception — $e');
      }

      done++;
      submitProgress.value = ((done / total) * 100).round();
      importRows.refresh();
    }

    // Refresh semua data setelah import selesai
    await Future.wait([
      _productC.fetchProducts(),
      _variantC.fetchAllVariants(),
      _priceC.fetchPrices(),
      _categoryC.fetchCategories(),
    ]);

    isSubmitting.value = false;
    importRows.refresh();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────────────────────────────────
  void clearImport() {
    importRows.clear();
    submitLog.clear();
    submitProgress.value = 0;
    parsedPriceListNames.clear();
  }

  String? _resolveCategoryId(String name) {
    if (name.isEmpty) return null;
    return _categoryC.findByName(name)?.id;
  }

  String? _resolveUnitId(String name) {
    if (name.isEmpty) return null;
    return _unitC.unitList
        .firstWhereOrNull(
          (u) => u.name.toLowerCase() == name.toLowerCase(),
        )
        ?.id;
  }

  void _markRowsSkipped(List<ImportRow> rows) {
    for (final r in rows) {
      r.status = ImportRowStatus.skipped;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TOP-LEVEL FUNCTIONS — dijalankan di isolate terpisah via compute()
// ─────────────────────────────────────────────────────────────────────────────

List<int> _buildTemplateBytes(List<String> priceListNames) {
  final excel = Excel.createExcel();
  final sheet = excel['Template Import Produk'];

  CellStyle headerStyle() => CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.fromHexString('#1E3A5F'),
        fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
      );

  CellStyle priceHeaderStyle() => CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.fromHexString('#2E6DA4'),
        fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
        horizontalAlign: HorizontalAlign.Center,
      );

  CellStyle noteStyle() => CellStyle(
        fontColorHex: ExcelColor.fromHexString('#856404'),
        backgroundColorHex: ExcelColor.fromHexString('#FFF3CD'),
        bold: true,
      );

  CellStyle exampleStyle() => CellStyle(
        fontColorHex: ExcelColor.fromHexString('#555555'),
        italic: true,
      );

  CellStyle exampleNumberStyle() => CellStyle(
        fontColorHex: ExcelColor.fromHexString('#555555'),
        italic: true,
        horizontalAlign: HorizontalAlign.Right,
        numberFormat: NumFormat.custom(formatCode: '#,##0'),
      );

  // ── Header ────────────────────────────────────────────────────────────────
  final fixedCols = [
    'Nama Produk *',
    'SKU Code *',
    'Kategori',
    'Nama Varian *',
    'Satuan *',
    'Stok',
  ];

  int col = 0;
  for (final h in fixedCols) {
    final cell = sheet.cell(
      CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0),
    );
    cell.value = TextCellValue(h);
    cell.cellStyle = headerStyle();
    col++;
  }

  for (final plName in priceListNames) {
    final cell = sheet.cell(
      CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0),
    );
    cell.value = TextCellValue('Harga $plName');
    cell.cellStyle = priceHeaderStyle();
    col++;
  }

  // ── Contoh baris 1 ────────────────────────────────────────────────────────
  void writeRow(int rowIdx, List<dynamic> values, List<double> prices) {
    for (int c = 0; c < values.length; c++) {
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: c, rowIndex: rowIdx),
      );
      final v = values[c];
      cell.value = v is int ? IntCellValue(v) : TextCellValue(v.toString());
      cell.cellStyle = v is int ? exampleNumberStyle() : exampleStyle();
    }
    for (int p = 0; p < prices.length; p++) {
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(
          columnIndex: values.length + p,
          rowIndex: rowIdx,
        ),
      );
      cell.value = DoubleCellValue(prices[p]);
      cell.cellStyle = exampleNumberStyle();
    }
  }

  writeRow(
    1,
    ['Aqua', 'PRD-001', 'Minuman', 'Aqua 600ml', 'Pieces', 100],
    priceListNames.map((n) => n.toLowerCase() == 'normal' ? 4000.0 : 3500.0).toList(),
  );

  writeRow(
    2,
    ['Aqua', 'PRD-001', 'Minuman', 'Aqua 1500ml', 'Pieces', 50],
    priceListNames.map((n) => n.toLowerCase() == 'normal' ? 7000.0 : 6000.0).toList(),
  );

  writeRow(
    3,
    ['Sprite', 'PRD-002', 'Minuman', 'Sprite 330ml', 'Pieces', 80],
    priceListNames.map((n) => n.toLowerCase() == 'normal' ? 5000.0 : 4500.0).toList(),
  );

  // ── Catatan ───────────────────────────────────────────────────────────────
  final noteCell = sheet.cell(
    CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 5),
  );
  noteCell.value = TextCellValue(
    '* = wajib diisi  |  '
    'SKU sama = variant satu produk  |  '
    'Hapus baris contoh sebelum upload  |  '
    'Satuan harus sesuai nama di master data app',
  );
  noteCell.cellStyle = noteStyle();

  // ── Column widths ─────────────────────────────────────────────────────────
  sheet.setColumnWidth(0, 22);
  sheet.setColumnWidth(1, 14);
  sheet.setColumnWidth(2, 18);
  sheet.setColumnWidth(3, 22);
  sheet.setColumnWidth(4, 12);
  sheet.setColumnWidth(5, 10);
  for (int i = 0; i < priceListNames.length; i++) {
    sheet.setColumnWidth(6 + i, 16);
  }

  excel.delete('Sheet1');
  final encoded = excel.encode();
  if (encoded == null) throw Exception('Gagal encode template');
  return encoded;
}

// ── Excel parser (isolate) ────────────────────────────────────────────────────
_ParseResult _parseExcelBytes(_ParsePayload payload) {
  final excel = Excel.decodeBytes(payload.bytes);
  final sheetName = excel.sheets.keys.first;
  final sheet = excel.sheets[sheetName]!;
  final rows = sheet.rows;

  if (rows.isEmpty) {
    return const _ParseResult(rows: [], priceListNames: []);
  }

  // ── Parse header ──────────────────────────────────────────────────────────
  final headerRow = rows[0];
  final headers = headerRow
      .map((c) => c?.value?.toString().trim().toLowerCase() ?? '')
      .toList();

  int findCol(String keyword) =>
      headers.indexWhere((h) => h.contains(keyword.toLowerCase()));

  final colProduct = findCol('nama produk');
  final colSku = findCol('sku');
  final colCategory = findCol('kategori');
  final colVariant = findCol('nama varian');
  final colUnit = findCol('satuan');
  final colStock = findCol('stok');

  // Kolom harga dinamis
  final priceColMap = <int, String>{};
  for (int i = 0; i < headers.length; i++) {
    final h = headers[i];
    if (h.startsWith('harga ')) {
      final raw = h.replaceFirst('harga ', '').trim();
      if (raw.isNotEmpty) {
        priceColMap[i] = raw[0].toUpperCase() + raw.substring(1);
      }
    }
  }

  // Validasi kolom wajib
  if ([colProduct, colSku, colVariant, colUnit].any((c) => c == -1)) {
    return _ParseResult(
      rows: [
        ImportRow(
          rowIndex: 1,
          productName: '',
          skuCode: '',
          categoryName: '',
          variantName: '',
          unitName: '',
          stockQty: 0,
          prices: {},
          errors: ['Header tidak valid. Gunakan template yang disediakan.'],
          status: ImportRowStatus.error,
        ),
      ],
      priceListNames: [],
    );
  }

  // ── Helper ambil nilai cell ───────────────────────────────────────────────
  String cellStr(List<Data?> row, int col) {
    if (col < 0 || col >= row.length) return '';
    return row[col]?.value?.toString().trim() ?? '';
  }

  // Track duplikat dalam file
  final seenVariants = <String>{};
  final parsedRows = <ImportRow>[];

  for (int r = 1; r < rows.length; r++) {
    final row = rows[r];

    // Skip baris kosong
    if (row.every((c) => (c?.value?.toString() ?? '').isEmpty)) continue;

    final productName = cellStr(row, colProduct);
    final skuCode = cellStr(row, colSku);
    final categoryName = colCategory >= 0 ? cellStr(row, colCategory) : '';
    final variantName = cellStr(row, colVariant);
    final unitName = cellStr(row, colUnit);
    final stockQty = int.tryParse(
          cellStr(row, colStock).replaceAll(',', '').replaceAll('.', ''),
        ) ??
        0;

    final errors = <String>[];

    if (productName.isEmpty) errors.add('Nama produk kosong');
    if (skuCode.isEmpty) errors.add('SKU kosong');
    if (variantName.isEmpty) errors.add('Nama varian kosong');
    if (unitName.isEmpty) errors.add('Satuan kosong');

    if (unitName.isNotEmpty &&
        !payload.validUnitNames.contains(unitName.toLowerCase())) {
      errors.add('Satuan "$unitName" tidak ada di master data');
    }

    if (skuCode.isNotEmpty &&
        payload.existingSkus.contains(skuCode.toLowerCase())) {
      errors.add('SKU "$skuCode" sudah ada di sistem');
    }

    final variantKey = '${skuCode.toLowerCase()}|${variantName.toLowerCase()}';
    if (seenVariants.contains(variantKey)) {
      errors.add('Duplikat varian "$variantName" untuk SKU "$skuCode"');
    } else {
      seenVariants.add(variantKey);
    }

    // Parse harga
    final prices = <String, double>{};
    for (final entry in priceColMap.entries) {
      final raw = cellStr(row, entry.key)
          .replaceAll(',', '')
          .replaceAll('.', '');
      final val = double.tryParse(raw) ?? 0;
      if (val > 0) prices[entry.value] = val;
    }

    parsedRows.add(
      ImportRow(
        rowIndex: r + 1,
        productName: productName,
        skuCode: skuCode,
        categoryName: categoryName,
        variantName: variantName,
        unitName: unitName,
        stockQty: stockQty,
        prices: prices,
        errors: errors,
        status: errors.isEmpty ? ImportRowStatus.valid : ImportRowStatus.error,
      ),
    );
  }

  return _ParseResult(
    rows: parsedRows,
    priceListNames: priceColMap.values.toList(),
  );
}