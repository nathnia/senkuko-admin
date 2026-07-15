// FILE: lib/features/products/pages/import_product_page.dart
//
// 3 state UI:
//   State 1 — Empty: tombol download template + upload file
//   State 2 — Preview: tabel hasil parse (valid/error per baris) + tombol import
//   State 3 — Result: progress + log setelah import selesai

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:senkukoadmin/constant/app_colors.dart';
import 'package:senkukoadmin/features/products/controllers/import_controller.dart';

class ImportProductPage extends StatelessWidget {
  const ImportProductPage({super.key});

  @override
  Widget build(BuildContext context) {
    final importC = Get.find<ImportController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
            color: Colors.black87,
          ),
          onPressed: () {
            importC.clearImport();
            Get.back();
          },
        ),
        title: const Text(
          'Import Produk',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
        actions: [
          Obx(() {
            if (!importC.hasData) return const SizedBox.shrink();
            return TextButton(
              onPressed: importC.isSubmitting.value
                  ? null
                  : () => importC.clearImport(),
              child: Text(
                'Reset',
                style: TextStyle(
                  color: importC.isSubmitting.value
                      ? Colors.grey
                      : AppColors.primary,
                  fontSize: 14,
                ),
              ),
            );
          }),
        ],
      ),
      body: Obx(() {
        // State 3 — sedang atau sudah submit
        if (importC.isSubmitting.value ||
            importC.importRows.any(
              (r) =>
                  r.status == ImportRowStatus.imported ||
                  r.status == ImportRowStatus.skipped,
            )) {
          return _SubmitView(importC: importC);
        }

        // State 2 — file sudah diparsing
        if (importC.hasData) {
          return _PreviewView(importC: importC);
        }

        // State 1 — belum ada file
        return _EmptyView(importC: importC);
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STATE 1 — EMPTY
// ─────────────────────────────────────────────────────────────────────────────
class _EmptyView extends StatelessWidget {
  final ImportController importC;
  const _EmptyView({required this.importC});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.table_chart_outlined,
              size: 36,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Import Produk dari Excel',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Download template, isi data produk,\nlalu upload kembali.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 32),

          _StepRow(
            number: '1',
            label: 'Download template Excel',
            action: Obx(
              () => _OutlineButton(
                label: 'Download Template',
                icon: Icons.download_rounded,
                isLoading: importC.isDownloadingTemplate.value,
                onTap: importC.downloadTemplate,
              ),
            ),
          ),
          const SizedBox(height: 16),
          _StepRow(
            number: '2',
            label: 'Isi data produk di Excel',
            action: Text(
              'Isi sesuai format, hapus baris contoh',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
            ),
          ),
          const SizedBox(height: 16),
          _StepRow(
            number: '3',
            label: 'Upload file yang sudah diisi',
            action: Obx(
              () => _OutlineButton(
                label: 'Pilih File .xlsx',
                icon: Icons.upload_file_rounded,
                isLoading: importC.isParsing.value,
                onTap: importC.pickAndParseFile,
              ),
            ),
          ),

          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 16,
                  color: Colors.amber.shade700,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Satuan produk harus sesuai dengan nama satuan yang sudah ada di master data. '
                    'Kategori yang belum ada akan dibuat otomatis.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.amber.shade800,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  final String number;
  final String label;
  final Widget action;

  const _StepRow({
    required this.number,
    required this.label,
    required this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              action,
            ],
          ),
        ),
      ],
    );
  }
}

class _OutlineButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isLoading;
  final VoidCallback onTap;

  const _OutlineButton({
    required this.label,
    required this.icon,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          border: Border.all(
            color: isLoading ? Colors.grey.shade300 : AppColors.primary,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLoading)
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              )
            else
              Icon(icon, size: 14, color: AppColors.primary),
            const SizedBox(width: 6),
            Text(
              isLoading ? 'Memproses...' : label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isLoading ? Colors.grey : AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STATE 2 — PREVIEW
// ─────────────────────────────────────────────────────────────────────────────
class _PreviewView extends StatelessWidget {
  final ImportController importC;
  const _PreviewView({required this.importC});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Summary bar ──────────────────────────────────────────────────────
        Obx(() {
          final validCount = importC.validRows.length;
          final errorCount = importC.errorRows.length;

          return Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: Row(
              children: [
                _SummaryChip(
                  count: validCount,
                  label: 'Siap import',
                  color: Colors.green.shade600,
                  bgColor: Colors.green.shade50,
                ),
                const SizedBox(width: 10),
                if (errorCount > 0) ...[
                  _SummaryChip(
                    count: errorCount,
                    label: 'Error',
                    color: Colors.red.shade600,
                    bgColor: Colors.red.shade50,
                  ),
                  const SizedBox(width: 10),
                ],
                const Spacer(),
                Text(
                  '${importC.importRows.length} baris total',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ),
          );
        }),

        const SizedBox(height: 8),

        // ── List preview ─────────────────────────────────────────────────────
        Expanded(
          child: Obx(
            () => ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
              itemCount: importC.importRows.length,
              itemBuilder: (context, i) {
                final row = importC.importRows[i];
                return _PreviewRowCard(row: row);
              },
            ),
          ),
        ),

        // ── Submit button ─────────────────────────────────────────────────────
        _SubmitBar(importC: importC),
      ],
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final int count;
  final String label;
  final Color color;
  final Color bgColor;

  const _SummaryChip({
    required this.count,
    required this.label,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$count $label',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _PreviewRowCard extends StatelessWidget {
  final ImportRow row;
  const _PreviewRowCard({required this.row});

  @override
  Widget build(BuildContext context) {
    final hasError = row.errors.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: hasError ? Colors.red.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: hasError ? Colors.red.shade200 : Colors.grey.shade100,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row number
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: hasError ? Colors.red.shade100 : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Text(
                '${row.rowIndex}',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: hasError ? Colors.red.shade700 : Colors.grey.shade600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row.displayTitle,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: hasError ? Colors.red.shade800 : Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  row.displaySubtitle,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
                if (row.prices.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    children: row.prices.entries
                        .map(
                          (e) => Text(
                            '${e.key}: Rp ${e.value.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
                // Error messages
                if (hasError) ...[
                  const SizedBox(height: 6),
                  ...row.errors.map(
                    (e) => Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline_rounded,
                            size: 12,
                            color: Colors.red.shade600,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              e,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.red.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Icon(
            hasError ? Icons.cancel_rounded : Icons.check_circle_rounded,
            size: 18,
            color: hasError ? Colors.red.shade400 : Colors.green.shade400,
          ),
        ],
      ),
    );
  }
}

class _SubmitBar extends StatelessWidget {
  final ImportController importC;
  const _SubmitBar({required this.importC});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        12 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Obx(
        () => SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            onPressed: importC.canSubmit ? importC.submitImport : null,
            child: importC.isSubmitting.value
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    'Import ${importC.validRows.length} Produk',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STATE 3 — SUBMIT PROGRESS & RESULT
// ─────────────────────────────────────────────────────────────────────────────
class _SubmitView extends StatelessWidget {
  final ImportController importC;
  const _SubmitView({required this.importC});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isSubmitting = importC.isSubmitting.value;
      final progress = importC.submitProgress.value;
      final imported = importC.importedCount;
      final total = importC.importRows.length;

      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header status ──────────────────────────────────────────────
            Center(
              child: Column(
                children: [
                  if (isSubmitting) ...[
                    SizedBox(
                      width: 56,
                      height: 56,
                      child: CircularProgressIndicator(
                        value: progress / 100,
                        strokeWidth: 5,
                        color: AppColors.primary,
                        backgroundColor: Colors.grey.shade200,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Mengimport... $progress%',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ] else ...[
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check_rounded,
                        size: 30,
                        color: Colors.green.shade600,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Import Selesai',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$imported dari $total variant berhasil diimport',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Log ────────────────────────────────────────────────────────
            Text(
              'Log',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade900,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ListView.builder(
                  itemCount: importC.submitLog.length,
                  itemBuilder: (context, i) {
                    final line = importC.submitLog[i];
                    final isError = line.startsWith('❌');
                    final isWarning = line.startsWith('  ⚠️');
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        line,
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily: 'monospace',
                          color: isError
                              ? Colors.red.shade300
                              : isWarning
                              ? Colors.yellow.shade300
                              : Colors.green.shade300,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            if (!isSubmitting) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () {
                    importC.clearImport();
                    Get.back();
                  },
                  child: const Text(
                    'Selesai',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    });
  }
}
