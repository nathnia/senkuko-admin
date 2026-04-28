import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:senkukoadmin/constant/currency_formatter.dart';
import 'package:senkukoadmin/features/products/controllers/product_controller.dart';
import 'package:senkukoadmin/features/products/controllers/product_variant_controller.dart';

class EditVariantDialog extends StatelessWidget {
  final int index;
  final ProductVariantController c;
  final controller = Get.find<ProductController>();

  EditVariantDialog({super.key, required this.index, required this.c});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Edit Variant'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Nama ──────────────────────────────
            TextField(
              onChanged: (_) => controller.isDirty.value = true,
              controller: c.dialogNameC,
              decoration: const InputDecoration(labelText: 'Nama Variant'),
            ),
            const SizedBox(height: 12),

            // ── Stock ─────────────────────────────
            TextField(
              onChanged: (_) => controller.isDirty.value = true,
              controller: c.dialogStockC,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(labelText: 'Stock Qty'),
            ),
            const SizedBox(height: 12),

            // ── Barcode ───────────────────────────
            TextField(
              onChanged: (_) => controller.isDirty.value = true,
              controller: c.dialogBarcodeC,
              decoration: const InputDecoration(
                labelText: 'Barcode (opsional)',
              ),
            ),
            const SizedBox(height: 16),

            // ── Unit ──────────────────────────────
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Unit',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 6),

            Obx(
              () => DropdownButtonFormField<String>(
                value: c.unitList.any((u) => u.id == c.dialogUnitId.value)
                    ? c.dialogUnitId.value
                    : null,
                isExpanded: true,
                hint: const Text('Pilih Unit'),
                items: c.unitList
                    .map(
                      (u) => DropdownMenuItem<String>(
                        value: u.id,
                        child: Text('${u.name} (${u.symbol})'),
                      ),
                    )
                    .toList(),
                onChanged: (val) {
                  if (val != null) c.dialogUnitId.value = val;
                  controller.isDirty.value = true;
                },
                decoration: const InputDecoration(labelText: 'Pilih Unit'),
              ),
            ),

            const SizedBox(height: 24),
            const Divider(),

            // ── Harga per Price List ───────────────
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Harga per Price List',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),

            // Obx menggantikan StatefulBuilder untuk price list
            Obx(
              () => Column(
                children: c.priceListMaster.map((pl) {
                  final entry = c.dialogPrices[pl.id];
                  final enabled = entry?['enabled'] as bool? ?? false;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Expanded(flex: 2, child: Text(pl.name)),
                        Expanded(
                          flex: 3,
                          child: TextField(
                            onChanged: (_) => controller.isDirty.value = true,
                            controller: c.dialogPriceC[pl.id],
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              CurrencyInputFormatter(),
                            ],
                            enabled: enabled,
                            decoration: InputDecoration(
                              hintText: '0',
                              prefixText: 'Rp ',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            enabled
                                ? Icons.check_circle
                                : Icons.add_circle_outline,
                            color: enabled ? Colors.green : Colors.grey,
                          ),
                          onPressed: () => c.togglePrice(pl.id, isDialog: true),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('Batal')),
        ElevatedButton(
          onPressed: () => c.saveEditVariantDialog(index),
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}
