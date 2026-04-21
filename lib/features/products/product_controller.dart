import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:senkukoadmin/features/products/models/category_model.dart';
import 'package:senkukoadmin/features/products/models/product_model.dart';
import 'package:senkukoadmin/features/products/models/product_price_model.dart';
import 'package:senkukoadmin/features/products/models/product_pricelist_model.dart';
import 'package:senkukoadmin/features/products/models/product_variant_model.dart';
import 'package:senkukoadmin/features/products/models/unit_model.dart';
import 'package:senkukoadmin/features/products/product_service.dart';
import 'package:senkukoadmin/routes/routes.dart';

class ProductController extends GetxController {
  void resetForAddProduct() {
    isEditMode.value = false;
    editingProductId.value = '';

    nameC.clear();
    skuC.clear();
    descC.clear();
    barcodeC.clear();
    selectedCategoryId.value = '';
    selectedUnitId.value = '';

    variantsTemp.clear();
    editVariantsTemp.clear();
    productVariants.clear();
    selectedProduct.value = null;

    for (var c in priceControllers.values) {
      c.clear();
    }

    debugPrint("✅ Reset berhasil untuk Add Product Baru");
  }

  // ===================== DELETE PRODUCT =====================
  Future<void> deleteProduct(String productId, String productName) async {
    if (productId.isEmpty) {
      Get.snackbar("Error", "Product ID tidak ditemukan");
      return;
    }

    debugPrint("🔥 deleteProduct dipanggil dengan ID: $productId");

    // Gunakan Get.dialog + RxBool agar lebih reliable
    final RxBool isConfirmed = false.obs;

    await Get.dialog(
      AlertDialog(
        title: const Text("Hapus Produk"),
        content: Text(
          "Yakin ingin menghapus produk ini?\n\n"
          "$productName\n\n"
          "Semua variant dan harga akan ikut terhapus secara permanen.",
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text("Batal")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              isConfirmed.value = true;
              Get.back();
            },
            child: const Text(
              "Ya, Hapus",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      barrierDismissible: false,
    );

    if (!isConfirmed.value) {
      debugPrint("❌ User batal menghapus");
      return;
    }

    // === PROSES DELETE ===
    try {
      isSubmitting.value = true;
      debugPrint("🗑 Mulai proses delete produk: $productId - $productName");

      final res = await ProductService.deleteProduct(productId);

      debugPrint("📡 Response Status: ${res.statusCode}");
      debugPrint("📡 Response Body: ${res.body}");

      if (res.statusCode == 200 || res.statusCode == 204) {
        Get.snackbar(
          "Sukses",
          "Produk '$productName' berhasil dihapus",
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );

        await fetchProducts();
        Get.back(); // Kembali ke list
      } else if (res.statusCode == 404) {
        Get.snackbar("Tidak Ditemukan", "Produk sudah tidak ada");
      } else {
        String message = "Gagal menghapus produk";
        try {
          final body = json.decode(res.body);
          message = body["message"] ?? message;
        } catch (_) {}
        Get.snackbar("Gagal", message);
      }
    } catch (e, stack) {
      debugPrint("❌ ERROR deleteProduct: $e");
      debugPrint("Stack: $stack");
      Get.snackbar("Error", "Terjadi kesalahan saat menghapus produk");
    } finally {
      isSubmitting.value = false;
    }
  }

  // ===================== STATE =====================
  final isLoading = false.obs;
  final isLoadingDetail = false.obs;
  final isSubmitting = false.obs;
  final isEditMode = false.obs;
  final editingProductId = ''.obs;

  final priceListMaster = <PricelistData>[].obs;
  final productList = <ProductData>[].obs;
  final categoryList = <CategoryData>[].obs;
  final unitList = <UnitData>[].obs;
  final priceList = <PriceData>[].obs;

  final selectedProduct = Rxn<ProductData>();
  final productVariants = <VariantData>[].obs;
  final editVariantsTemp = <Map<String, dynamic>>[].obs;
  final variantsTemp = <Map<String, dynamic>>[].obs;

  // ===================== FORM =====================
  final nameC = TextEditingController();
  final skuC = TextEditingController();
  final descC = TextEditingController();
  final barcodeC = TextEditingController();
  final selectedCategoryId = ''.obs;
  final selectedUnitId = ''.obs;

  // ===================== VARIANT FORM =====================
  final variantNameC = TextEditingController();
  final variantStockC = TextEditingController();
  final variantBarcodeC = TextEditingController();
  final Map<String, TextEditingController> priceControllers = {};

  @override
  void onInit() {
    super.onInit();
    loadInitialData();
  }

  Future<void> loadInitialData() async {
    isLoading.value = true;
    try {
      await Future.wait([
        fetchProducts(),
        fetchCategories(),
        fetchUnits(),
        fetchPrices(),
        fetchPriceLists(),
      ]);
    } catch (e) {
      Get.snackbar('Error', 'Gagal memuat data awal');
    } finally {
      isLoading.value = false;
    }
  }

  // ===================== FETCH =====================
  Future<void> fetchPriceLists() async {
    final res = await ProductService.getPriceLists();
    if (res.statusCode == 200) {
      final data = priceListModelFromJson(res.body);
      priceListMaster.assignAll(data.data);
    }
  }

  Future<void> fetchProducts() async {
    final res = await ProductService.getProducts();
    if (res.statusCode == 200) {
      final data = productModelFromJson(res.body);
      productList.assignAll(data.data);
    }
  }

  Future<void> fetchPrices() async {
    final res = await ProductService.getPrices();
    if (res.statusCode == 200) {
      final data = productPriceModelFromJson(res.body);
      priceList.assignAll(data.data);
    }
  }

  Future<void> fetchUnits() async {
    final res = await ProductService.getUnits();
    if (res.statusCode == 200) {
      final jsonData = json.decode(res.body);
      unitList.assignAll(
        (jsonData['data'] as List? ?? [])
            .map((e) => UnitData.fromJson(e))
            .toList(),
      );
    }
  }

  Future<void> fetchCategories() async {
    final res = await ProductService.getCategories();
    if (res.statusCode == 200) {
      final jsonData = json.decode(res.body);
      categoryList.assignAll(
        (jsonData['data'] as List? ?? [])
            .map((e) => CategoryData.fromJson(e))
            .toList(),
      );
    }
  }

  // ===================== LOAD DETAIL =====================
  Future<void> loadProductDetail(String productId) async {
    isLoadingDetail.value = true;
    selectedProduct.value = null;
    productVariants.clear();

    try {
      final results = await Future.wait([
        ProductService.getVariants(productId),
        ProductService.getProductById(productId),
      ]);

      final variantRes = results[0];
      final productRes = results[1];

      if (variantRes.statusCode == 200) {
        final jsonData = json.decode(variantRes.body);
        final List raw = jsonData['data']?['variants'] ?? [];

        // DEBUG
        debugPrint("✅ Ditemukan ${raw.length} variants dari API");

        productVariants.assignAll(
          raw.map((e) => VariantData.fromJson(e)).toList(),
        );
      } else {
        debugPrint("❌ Gagal get variants: ${variantRes.statusCode}");
      }

      if (productRes.statusCode == 200) {
        final jsonData = json.decode(productRes.body);
        if (jsonData['data'] != null) {
          selectedProduct.value = ProductData.fromJson(jsonData['data']);
        }
      }
    } catch (e) {
      debugPrint("Error loadProductDetail: $e");
      Get.snackbar("Error", "Gagal memuat detail produk");
    } finally {
      isLoadingDetail.value = false;
    }
  }

  // ===================== LOAD EDIT DATA =====================
  Future<void> loadEditData(String productId) async {
    isEditMode.value = true;
    editingProductId.value = productId;

    if (priceListMaster.isEmpty) await fetchPriceLists();
    if (unitList.isEmpty) await fetchUnits();

    await loadProductDetail(productId);

    editVariantsTemp.clear();

    debugPrint("🔄 Memproses ${productVariants.length} variants...");

    for (var v in productVariants) {
      List<Map<String, dynamic>> prices = [];
      try {
        final res = await ProductService.getPricesByVariant(v.id);
        if (res.statusCode == 200) {
          final jsonData = json.decode(res.body);
          dynamic data = jsonData["data"];
          List rawList = (data is Map
              ? data["prices"] ?? []
              : (data as List? ?? []));

          prices = rawList.map((e) {
            final m = Map<String, dynamic>.from(e as Map);
            final rawPrice = m["price"]?.toString() ?? "0";
            return {
              "id": m["id"]?.toString() ?? "",
              "price_list_id": m["price_list_id"]?.toString() ?? "",
              "price": double.tryParse(rawPrice)?.toStringAsFixed(0) ?? "0",
            };
          }).toList();
        }
      } catch (e) {
        debugPrint("Gagal load harga variant ${v.id}: $e");
      }

      String unitId = "";
      if (v.unitId != null && v.unitId.toString().trim().isNotEmpty) {
        unitId = v.unitId.toString().trim();
      } else if (v.unitName != null && unitList.isNotEmpty) {
        // Fallback berdasarkan nama unit jika ID kosong
        final matchingUnit = unitList.firstWhereOrNull(
          (u) => u.name.toLowerCase() == v.unitName!.toLowerCase(),
        );
        if (matchingUnit != null) {
          unitId = matchingUnit.id;
          debugPrint("✅ Match unit by name: ${v.unitName} → $unitId");
        }
      }

      // Fallback terakhir hanya jika benar-benar tidak ada
      if (unitId.isEmpty && unitList.isNotEmpty) {
        unitId = unitList.first.id;
        debugPrint("⚠ Fallback ke unit pertama untuk ${v.name}");
      }

      editVariantsTemp.add({
        "id": v.id,
        "name": v.name,
        "stock_qty": v.stockQty,
        "barcode": v.barcode ?? "",
        "unit_id": unitId,
        "unit_name": v.unitName ?? "",
        "is_base_unit": v.isBaseUnit == 1,
        "conversion_factor":
            double.tryParse(v.conversionFactor.toString()) ?? 1.0,
        "prices": prices,
      });

      debugPrint(
        "Added variant: ${v.name} | unit_id = $unitId | unit_name = ${v.unitName}",
      );
    }

    editVariantsTemp.refresh();

    debugPrint("\n=== LOAD EDIT DATA SELESAI ===");
    for (int i = 0; i < editVariantsTemp.length; i++) {
      final item = editVariantsTemp[i];
      final unitMatch = unitList.firstWhereOrNull(
        (u) => u.id == item['unit_id'],
      );
      debugPrint(
        "Variant ${i + 1}: ${item['name']} | unit_id = ${item['unit_id']} → ${unitMatch?.name ?? 'NOT FOUND'}",
      );
    }

    // Isi form produk
    final p = selectedProduct.value;
    if (p != null) {
      nameC.text = p.name;
      skuC.text = p.skuCode;
      descC.text = p.description ?? '';
      barcodeC.text = p.barcode ?? '';
      selectedCategoryId.value = p.categoryId ?? '';
    }

    initPriceControllers(priceListMaster);
  }

  // ===================== UPDATE FULL PRODUCT =====================
  Future<void> updateFullProduct() async {
    if (editingProductId.value.isEmpty) {
      Get.snackbar("Error", "Product ID tidak ditemukan");
      return;
    }

    isSubmitting.value = true;
    debugPrint("=== START UPDATE FULL PRODUCT ===");

    try {
      // ── 1. UPDATE PRODUK UTAMA ────────────────────────────────────────
      final productRes = await ProductService.updateProduct(
        id: editingProductId.value,
        name: nameC.text.trim(),
        skuCode: skuC.text.trim(),
        description: descC.text.trim(),
        barcode: barcodeC.text.trim(),
        categoryId: selectedCategoryId.value.isEmpty
            ? null
            : selectedCategoryId.value,
      );

      if (productRes.statusCode < 200 || productRes.statusCode >= 300) {
        debugPrint("❌ Gagal update produk: ${productRes.body}");
        Get.snackbar("Error", "Gagal update informasi produk");
        return;
      }
      debugPrint("✅ Produk utama berhasil diupdate");

      // ── 2. UPDATE SETIAP VARIANT ──────────────────────────────────────
      for (var v in editVariantsTemp) {
        final variantId = v["id"]?.toString() ?? "";

        // Variant baru (belum punya ID di DB) → create
        if (variantId.isEmpty) {
          await _createNewVariant(v);
          continue;
        }

        final unitIdToSend = v["unit_id"]?.toString() ?? "";
        if (unitIdToSend.isEmpty) {
          debugPrint("⚠ unit_id kosong untuk variant ${v["name"]}, skip.");
          continue;
        }

        final barcodeToSend = v["barcode"]?.toString().trim() ?? "";
        final isBaseUnit = v["is_base_unit"] as bool? ?? false;

        debugPrint(
          "Updating variant: ${v["name"]} | "
          "barcode: '$barcodeToSend' | "
          "isBaseUnit: $isBaseUnit",
        );

        final variantRes = await ProductService.updateVariant(
          id: variantId,
          name: v["name"]?.toString() ?? "",
          stock: int.tryParse(v["stock_qty"]?.toString() ?? "0") ?? 0,
          unitId: unitIdToSend,
          barcode: barcodeToSend.isEmpty ? null : barcodeToSend,
          isBaseUnit: isBaseUnit,
        );

        if (variantRes.statusCode < 200 || variantRes.statusCode >= 300) {
          debugPrint(
            "❌ Gagal update variant ${v["name"]}: "
            "${variantRes.statusCode} | ${variantRes.body}",
          );
          continue;
        }
        debugPrint("✅ Variant ${v["name"]} berhasil diupdate");

        // ── 3. SINKRONISASI HARGA ─────────────────────────────────────
        await _syncPrices(
          variantId: variantId,
          newPrices: List<Map<String, dynamic>>.from(v["prices"] ?? []),
        );
      }

      Get.snackbar(
        "Sukses",
        "Produk berhasil diupdate",
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      await fetchProducts();
      await fetchPrices();
      Get.offNamed(AppRoutes.product);
    } catch (e, stack) {
      debugPrint("ERROR updateFullProduct: $e\n$stack");
      Get.snackbar("Error", "Terjadi kesalahan saat menyimpan perubahan");
    } finally {
      isSubmitting.value = false;
    }
  }

  /// Sinkronisasi harga: update yang sudah ada, hapus yang dihilangkan,
  /// create yang baru ditambahkan.
  Future<void> _syncPrices({
    required String variantId,
    required List<Map<String, dynamic>> newPrices,
  }) async {
    // Ambil harga terkini dari DB untuk variant ini
    List<Map<String, dynamic>> existingPrices = [];
    try {
      final res = await ProductService.getPricesByVariant(variantId);
      if (res.statusCode == 200) {
        final jsonData = json.decode(res.body);
        dynamic data = jsonData["data"];
        List rawList = [];
        if (data is Map) {
          rawList = data["prices"] ?? [];
        } else if (data is List) {
          rawList = data;
        }
        existingPrices = rawList
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      }
    } catch (e) {
      debugPrint("Gagal ambil harga existing: $e");
    }

    debugPrint(
      "Sync harga variant $variantId: "
      "existing=${existingPrices.length}, new=${newPrices.length}",
    );

    // Buat map: price_list_id → existing price entry
    final existingMap = <String, Map<String, dynamic>>{};
    for (var ep in existingPrices) {
      final plId = ep["price_list_id"]?.toString() ?? "";
      if (plId.isNotEmpty) existingMap[plId] = ep;
    }

    // Buat set: price_list_id yang ada di newPrices
    final newPriceListIds = newPrices
        .map((p) => p["price_list_id"]?.toString() ?? "")
        .where((id) => id.isNotEmpty)
        .toSet();

    // ── A. Update atau Create ───────────────────────────────────────────
    for (var np in newPrices) {
      final plId = np["price_list_id"]?.toString() ?? "";
      final priceValue = double.tryParse(np["price"]?.toString() ?? "0") ?? 0;

      if (plId.isEmpty || priceValue <= 0) continue;

      if (existingMap.containsKey(plId)) {
        // ✅ Sudah ada → UPDATE
        final existingId = existingMap[plId]!["id"]?.toString() ?? "";
        final existingPrice =
            double.tryParse(existingMap[plId]!["price"]?.toString() ?? "0") ??
            0;

        if (existingId.isNotEmpty && existingPrice != priceValue) {
          try {
            await ProductService.updatePrice(
              priceId: existingId,
              priceListId: plId,
              price: priceValue,
            );
            debugPrint("   ✅ Update harga $plId: $existingPrice → $priceValue");
          } catch (e) {
            debugPrint("   ⚠ Gagal update harga $plId: $e");
          }
        } else {
          debugPrint("   ℹ Harga $plId tidak berubah ($priceValue), skip.");
        }
      } else {
        // ✅ Belum ada → CREATE
        try {
          final createRes = await ProductService.createPrice(
            variantId: variantId,
            priceListId: plId,
            price: priceValue,
          );
          if (createRes.statusCode == 201) {
            debugPrint("   ✅ Create harga baru $plId: $priceValue");
          } else {
            debugPrint(
              "   ❌ Gagal create harga $plId: "
              "${createRes.statusCode} | ${createRes.body}",
            );
          }
        } catch (e) {
          debugPrint("   ⚠ Exception create harga $plId: $e");
        }
      }
    }

    // ── B. Hapus harga yang dihilangkan dari UI ─────────────────────────
    for (var ep in existingPrices) {
      final plId = ep["price_list_id"]?.toString() ?? "";
      final priceId = ep["id"]?.toString() ?? "";

      if (!newPriceListIds.contains(plId) && priceId.isNotEmpty) {
        // Cek apakah ini satu-satunya harga variant (backend tidak boleh hapus)
        if (existingPrices.length == 1) {
          debugPrint("   ⚠ Tidak bisa hapus harga terakhir variant $variantId");
          continue;
        }
        try {
          final deleteRes = await ProductService.deletePrice(priceId);
          if (deleteRes.statusCode == 200) {
            debugPrint("   🗑 Hapus harga $plId (ID: $priceId)");
          } else {
            debugPrint(
              "   ❌ Gagal hapus harga $priceId: "
              "${deleteRes.statusCode} | ${deleteRes.body}",
            );
          }
        } catch (e) {
          debugPrint("   ⚠ Exception hapus harga $priceId: $e");
        }
      }
    }
  }

  /// Buat variant baru (untuk variant yang ditambahkan saat edit)
  Future<void> _createNewVariant(Map<String, dynamic> v) async {
    final variantRes = await ProductService.createVariant(
      productId: editingProductId.value,
      unitId: v["unit_id"]?.toString() ?? "",
      name: v["name"]?.toString() ?? "",
      stock: int.tryParse(v["stock_qty"]?.toString() ?? "0") ?? 0,
      barcode: v["barcode"]?.toString().trim(),
      isBaseUnit: v["is_base_unit"] as bool? ?? false,
    );

    if (variantRes.statusCode == 201) {
      final newVariantId =
          json.decode(variantRes.body)['data']['id']?.toString() ?? "";
      debugPrint("✅ Variant baru dibuat: $newVariantId");

      for (var p in (v["prices"] as List? ?? [])) {
        final plId = p["price_list_id"]?.toString() ?? "";
        final price = double.tryParse(p["price"]?.toString() ?? "0") ?? 0;
        if (plId.isNotEmpty && price > 0) {
          await ProductService.createPrice(
            variantId: newVariantId,
            priceListId: plId,
            price: price,
          );
        }
      }
    } else {
      debugPrint(
        "❌ Gagal create variant baru: "
        "${variantRes.statusCode} | ${variantRes.body}",
      );
    }
  }

  // ===================== CREATE FULL PRODUCT =====================
  Future<bool> createFullProduct() async {
    if (nameC.text.trim().isEmpty || skuC.text.trim().isEmpty) {
      Get.snackbar('Validasi', 'Nama dan SKU Code harus diisi');
      return false;
    }
    if (variantsTemp.isEmpty) {
      Get.snackbar('Validasi', 'Minimal tambahkan 1 variant');
      return false;
    }

    isSubmitting.value = true;

    try {
      final productRes = await ProductService.createProduct(
        name: nameC.text.trim(),
        skuCode: skuC.text.trim(),
        description: descC.text.trim(),
        barcode: barcodeC.text.trim(),
        categoryId: selectedCategoryId.value.isEmpty
            ? null
            : selectedCategoryId.value,
      );

      if (productRes.statusCode != 201) {
        Get.snackbar('Gagal', 'Gagal membuat produk');
        return false;
      }

      final newProductId =
          json.decode(productRes.body)['data']['id']?.toString() ?? "";

      for (var v in variantsTemp) {
        final variantRes = await ProductService.createVariant(
          productId: newProductId,
          unitId: v["unit_id"],
          name: v["name"],
          stock: v["stock_qty"],
          barcode: v["barcode"]?.toString(),
        );

        if (variantRes.statusCode == 201) {
          final variantId =
              json.decode(variantRes.body)['data']['id']?.toString() ?? "";

          for (var p in (v["prices"] as List? ?? [])) {
            await ProductService.createPrice(
              variantId: variantId,
              priceListId: p["price_list_id"],
              price: double.tryParse(p["price"].toString()) ?? 0,
            );
          }
        }
      }

      await fetchProducts();
      await fetchPrices();
      clearForm();

      Get.snackbar(
        'Sukses',
        'Produk berhasil ditambahkan',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      return true;
    } catch (e) {
      Get.snackbar('Error', 'Terjadi kesalahan saat menyimpan');
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  // ===================== OPEN EDIT VARIANT POPUP =====================
  // ===================== OPEN EDIT VARIANT POPUP =====================
  void openEditVariantPopup(int index) {
    if (index < 0 || index >= editVariantsTemp.length) return;

    final v = Map<String, dynamic>.from(editVariantsTemp[index]);

    final localNameC = TextEditingController(text: v["name"]?.toString() ?? "");
    final localStockC = TextEditingController(
      text: v["stock_qty"]?.toString() ?? "0",
    );
    final localBarcodeC = TextEditingController(
      text: v["barcode"]?.toString() ?? "",
    );

    final selectedUnitIdLocal = (v["unit_id"]?.toString() ?? "").obs;

    // Price controllers
    final Map<String, TextEditingController> priceC = {};
    final Map<String, RxBool> priceEnabled = {};

    for (var pl in priceListMaster) {
      final existing = (v["prices"] as List?)?.firstWhereOrNull(
        (e) => (e["price_list_id"]?.toString() ?? "") == pl.id,
      );
      priceC[pl.id] = TextEditingController(
        text: existing?["price"]?.toString() ?? "",
      );
      priceEnabled[pl.id] = (existing != null).obs;
    }

    Get.dialog(
      AlertDialog(
        title: Text("Edit Variant - ${v["name"]}"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: localNameC,
                decoration: const InputDecoration(labelText: "Nama Variant"),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: localStockC,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Stock Qty"),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: localBarcodeC,
                decoration: const InputDecoration(
                  labelText: "Barcode (opsional)",
                ),
              ),
              const SizedBox(height: 20),

              // ==================== FIXED UNIT DROPDOWN ====================
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Unit",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),

              Obx(() {
                final currentUnitId = selectedUnitIdLocal.value;
                final matchingUnit = unitList.firstWhereOrNull(
                  (u) => u.id == currentUnitId,
                );

                debugPrint(
                  "Dropdown rebuild - currentUnitId: '$currentUnitId' → ${matchingUnit?.name ?? 'NOT FOUND'}",
                );

                return DropdownButtonFormField<String>(
                  key: ValueKey(currentUnitId), // Force rebuild
                  value: matchingUnit != null ? currentUnitId : null,
                  isExpanded: true,
                  hint: const Text("Pilih Unit"),
                  items: unitList
                      .map(
                        (u) => DropdownMenuItem<String>(
                          value: u.id,
                          child: Text("${u.name} (${u.symbol})"),
                        ),
                      )
                      .toList(),
                  onChanged: (newValue) {
                    if (newValue != null) {
                      debugPrint(
                        "✅ User memilih unit BARU: $newValue - ${unitList.firstWhere((u) => u.id == newValue).name}",
                      );
                      selectedUnitIdLocal.value = newValue;
                    }
                  },
                  decoration: const InputDecoration(labelText: "Pilih Unit"),
                );
              }),

              const SizedBox(height: 30),
              const Divider(),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Harga per Price List",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 12),

              ...priceListMaster.map((pl) {
                return Obx(
                  () => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            pl.name,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: priceC[pl.id],
                            keyboardType: TextInputType.number,
                            enabled: priceEnabled[pl.id]!.value,
                            decoration: InputDecoration(
                              hintText: "0",
                              prefixText: "Rp ",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Obx(
                          () => IconButton(
                            icon: Icon(
                              priceEnabled[pl.id]!.value
                                  ? Icons.check_circle
                                  : Icons.add_circle_outline,
                              color: priceEnabled[pl.id]!.value
                                  ? Colors.green
                                  : Colors.grey,
                            ),
                            onPressed: () {
                              priceEnabled[pl.id]!.value =
                                  !priceEnabled[pl.id]!.value;
                              if (!priceEnabled[pl.id]!.value)
                                priceC[pl.id]?.clear();
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text("Batal")),
          ElevatedButton(
            onPressed: () {
              debugPrint("=== SIMPAN POPUP VARIANT ===");
              debugPrint(
                "Unit ID yang dipilih di dropdown: ${selectedUnitIdLocal.value}",
              );

              final List<Map<String, dynamic>> newPrices = [];
              for (var pl in priceListMaster) {
                final enabled = priceEnabled[pl.id]?.value ?? false;
                final val = priceC[pl.id]?.text.trim() ?? "";
                if (!enabled || val.isEmpty) continue;

                final oldPrice = (editVariantsTemp[index]["prices"] as List?)
                    ?.firstWhereOrNull(
                      (e) => (e["price_list_id"]?.toString() ?? "") == pl.id,
                    );

                newPrices.add({
                  "id": oldPrice?["id"] ?? "",
                  "price_list_id": pl.id,
                  "price": val,
                });
              }

              final updatedData = {
                "id": v["id"],
                "name": localNameC.text.trim(),
                "stock_qty": int.tryParse(localStockC.text.trim()) ?? 0,
                "barcode": localBarcodeC.text.trim().isEmpty
                    ? null
                    : localBarcodeC.text.trim(),
                "unit_id": selectedUnitIdLocal.value,
                "unit_name":
                    unitList
                        .firstWhereOrNull(
                          (u) => u.id == selectedUnitIdLocal.value,
                        )
                        ?.name ??
                    v["unit_name"] ??
                    "",
                "is_base_unit": v["is_base_unit"] ?? false,
                "conversion_factor": v["conversion_factor"] ?? 1.0,
                "prices": newPrices,
              };

              editVariantsTemp[index] = updatedData;
              editVariantsTemp.refresh();

              debugPrint(
                "✅ Sukses simpan ke editVariantsTemp | Unit ID = ${updatedData["unit_id"]}",
              );

              Get.back();

              Get.snackbar(
                "Tersimpan di Memory",
                "Unit: ${selectedUnitIdLocal.value}",
                backgroundColor: Colors.green[700],
                colorText: Colors.white,
              );
            },
            child: const Text("Simpan"),
          ),
        ],
      ),
    );
  }

  // ===================== VARIANT FORM HELPERS =====================
  void initPriceControllers(List<PricelistData> priceLists) {
    for (var p in priceLists) {
      priceControllers.putIfAbsent(p.id, () => TextEditingController());
    }
  }

  void clearVariantForm() {
    variantNameC.clear();
    variantStockC.clear();
    variantBarcodeC.clear();
    selectedUnitId.value = '';
    for (var c in priceControllers.values) {
      c.clear();
    }
  }

  void addVariantFromForm() {
    final stock = int.tryParse(variantStockC.text);
    if (variantNameC.text.isEmpty ||
        stock == null ||
        selectedUnitId.value.isEmpty) {
      Get.snackbar("Error", "Lengkapi data variant");
      return;
    }

    final unit = unitList.firstWhere((u) => u.id == selectedUnitId.value);

    List<Map<String, dynamic>> prices = [];
    priceControllers.forEach((id, c) {
      final price = double.tryParse(c.text);
      if (price != null && price > 0) {
        prices.add({"price_list_id": id, "price": price});
      }
    });

    final newVariant = {
      "id": "", // kosong = variant baru
      "name": variantNameC.text.trim(),
      "stock_qty": stock,
      "barcode": variantBarcodeC.text.isEmpty ? null : variantBarcodeC.text,
      "unit_id": unit.id,
      "unit_name": unit.name,
      "is_base_unit": false,
      "conversion_factor": 1.0,
      "prices": prices,
    };

    if (isEditMode.value) {
      editVariantsTemp.add(newVariant);
      editVariantsTemp.refresh();
    } else {
      variantsTemp.add(newVariant);
      variantsTemp.refresh();
    }

    clearVariantForm();
  }

  void removeTempVariant(int index) {
    if (isEditMode.value) {
      if (index >= 0 && index < editVariantsTemp.length) {
        editVariantsTemp.removeAt(index);
        editVariantsTemp.refresh();
      }
    } else {
      if (index >= 0 && index < variantsTemp.length) {
        variantsTemp.removeAt(index);
        variantsTemp.refresh();
      }
    }
  }

  void clearForm() {
    nameC.clear();
    skuC.clear();
    descC.clear();
    barcodeC.clear();
    selectedCategoryId.value = '';
    variantsTemp.clear();
  }

  // ===================== CATEGORY HELPERS =====================
  Future<String?> createCategory(String name) async {
    try {
      final res = await ProductService.createCategory(name);
      if (res.statusCode == 201) {
        final data = json.decode(res.body);
        return data['data']['id'];
      }
    } catch (e) {
      Get.snackbar("Error", "Gagal tambah category");
    }
    return null;
  }

  Future<void> deleteCategory(String id) async {
    try {
      final res = await ProductService.deleteCategory(id);
      if (res.statusCode == 200) {
        categoryList.removeWhere((c) => c.id == id);
        if (selectedCategoryId.value == id) selectedCategoryId.value = '';
        Get.snackbar("Sukses", "Category berhasil dihapus");
      } else {
        final data = json.decode(res.body);
        Get.snackbar("Gagal", data["message"] ?? "Tidak bisa hapus category");
      }
    } catch (e) {
      Get.snackbar("Error", "Terjadi kesalahan");
    }
  }

  // ===================== UNIT HELPERS =====================
  Future<String?> createUnit(String name, String symbol) async {
    if (name.isEmpty || symbol.isEmpty) {
      Get.snackbar("Error", "Nama & symbol wajib");
      return null;
    }
    if (unitList.any((u) => u.symbol == symbol)) {
      Get.snackbar("Error", "Symbol sudah ada");
      return null;
    }
    try {
      final res = await ProductService.createUnit(name: name, symbol: symbol);
      if (res.statusCode == 201) {
        final data = json.decode(res.body);
        await fetchUnits();
        Get.snackbar("Sukses", "Unit ditambahkan");
        return data["data"]["id"];
      } else {
        Get.snackbar("Error", "Gagal tambah unit");
      }
    } catch (e) {
      Get.snackbar("Error", "Terjadi kesalahan");
    }
    return null;
  }

  Future<void> deleteUnit(String id) async {
    try {
      final res = await ProductService.deleteUnit(id);
      if (res.statusCode == 200) {
        Get.snackbar("Sukses", "Unit berhasil dihapus");
        fetchUnits();
      } else {
        final body = json.decode(res.body);
        Get.snackbar("Gagal", body["message"] ?? "Gagal hapus unit");
      }
    } catch (e) {
      Get.snackbar("Error", "Terjadi kesalahan");
    }
  }

  // ===================== PRICE HELPERS =====================
  List<PriceData> getPricesByVariant(String variantId) {
    return priceList.where((e) => e.productVariantId == variantId).toList();
  }

  String getMainPriceForProduct(ProductData product) {
    if (priceList.isEmpty) return "0";
    final candidate = priceList.firstWhereOrNull((price) {
      final variantName = price.productVariantName.toLowerCase();
      final productName = product.name.toLowerCase();
      return variantName.contains(productName) ||
          productName.contains(variantName.split(' ').first);
    });
    return candidate?.price ?? "0";
  }

  int getAdditionalPriceCountForProduct(ProductData product) {
    if (priceList.isEmpty) return 0;
    final mainPrice = getMainPriceForProduct(product);
    if (mainPrice == "0") return 0;
    final count = priceList.where((price) {
      final variantName = price.productVariantName.toLowerCase();
      final productName = product.name.toLowerCase();
      return variantName.contains(productName) ||
          productName.contains(variantName.split(' ').first);
    }).length;
    return count > 1 ? count - 1 : 0;
  }

  @override
  void onClose() {
    nameC.dispose();
    skuC.dispose();
    descC.dispose();
    barcodeC.dispose();
    variantNameC.dispose();
    variantStockC.dispose();
    variantBarcodeC.dispose();
    for (var c in priceControllers.values) {
      c.dispose();
    }
    super.onClose();
  }
}
