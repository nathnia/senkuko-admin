import 'dart:convert';
import 'package:get/get.dart';
import 'package:senkukoadmin/constant/app_toast.dart';
import 'package:senkukoadmin/constant/cache_service.dart';
import 'package:senkukoadmin/features/products/models/unit_model.dart';
import 'package:senkukoadmin/features/products/product_service.dart';

class UnitController extends GetxController {
  final unitList = <UnitData>[].obs;
  final isLoading = false.obs; // ADDED — sebelumnya gak ada guard sama sekali

  // ===================== FETCH =====================
  Future<void> fetchUnits({bool forceRefresh = false}) async {
    if (isLoading.value) return;

    if (!forceRefresh) {
      final cached = CacheService.instance.get(
        CacheKeys.units,
        ttl: CacheKeys.referenceDataTtl,
      );
      if (cached != null) {
        unitList.assignAll(
          (cached as List).map((e) => UnitData.fromJson(e)).toList(),
        );
        return;
      }
    }

    isLoading.value = true;
    try {
      final res = await ProductService.getUnits();
      if (res.statusCode == 200) {
        final jsonData = json.decode(res.body);
        final list = (jsonData['data'] as List? ?? [])
            .map((e) => UnitData.fromJson(e))
            .toList();
        unitList.assignAll(list);
        await CacheService.instance.set(
          CacheKeys.units,
          list.map((u) => u.toJson()).toList(),
        );
      }
    } finally {
      isLoading.value = false;
    }
  }

  // ===================== CREATE =====================
  Future<String?> createUnit(String name, String symbol) async {
    if (name.isEmpty || symbol.isEmpty) {
      AppToast.show('Nama & symbol wajib');
      return null;
    }
    if (unitList.any((u) => u.symbol == symbol)) {
      AppToast.show('Symbol sudah ada');
      return null;
    }
    try {
      final res = await ProductService.createUnit(name: name, symbol: symbol);
      if (res.statusCode == 201) {
        await CacheService.instance.invalidate(CacheKeys.units);
        await fetchUnits(forceRefresh: true);
        AppToast.show('Unit ditambahkan');
        return json.decode(res.body)['data']['id'];
      }
      AppToast.show('Gagal tambah unit');
    } catch (e) {
      AppToast.show('Terjadi kesalahan');
    }
    return null;
  }

  // ===================== DELETE =====================
  Future<void> deleteUnit(String id) async {
    try {
      final res = await ProductService.deleteUnit(id);
      if (res.statusCode == 200) {
        AppToast.show('Unit berhasil dihapus');
        await CacheService.instance.invalidate(CacheKeys.units);
        await fetchUnits(forceRefresh: true);
      } else {
        AppToast.show(_parseErrorMessage(res.body));
      }
    } catch (e) {
      AppToast.show('Terjadi kesalahan');
    }
  }

  String _parseErrorMessage(String body) {
    try {
      return json.decode(body)['message'] ?? 'Terjadi kesalahan';
    } catch (_) {
      return 'Terjadi kesalahan';
    }
  }
}