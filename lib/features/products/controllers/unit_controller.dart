import 'dart:convert';
import 'package:get/get.dart';
import 'package:senkukoadmin/constant/app_toast.dart';
import 'package:senkukoadmin/features/products/models/unit_model.dart';
import 'package:senkukoadmin/features/products/product_service.dart';

class UnitController extends GetxController {
  final unitList = <UnitData>[].obs;

  // ===================== FETCH =====================
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
        await fetchUnits();
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
        await fetchUnits();
      } else {
        AppToast.show(_parseErrorMessage(res.body));
      }
    } catch (e) {
      AppToast.show('Terjadi kesalahan');
    }
  }

  // ===================== HELPERS =====================
  String _parseErrorMessage(String body) {
    try {
      return json.decode(body)['message'] ?? 'Terjadi kesalahan';
    } catch (_) {
      return 'Terjadi kesalahan';
    }
  }
}