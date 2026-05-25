// lib/features/products/controllers/category_controller.dart
import 'dart:convert';
import 'package:get/get.dart';
import 'package:senkukoadmin/constant/api_helper.dart';
import 'package:senkukoadmin/constant/app_toast.dart';
import 'package:senkukoadmin/features/products/models/category_model.dart';
import 'package:senkukoadmin/features/products/product_service.dart';

class CategoryController extends GetxController {
  final categoryList = <CategoryData>[].obs;
  final isLoading = false.obs;

  // ===================== GETTERS =====================
  List<CategoryData> get parentCategories =>
      categoryList.where((c) => c.parentId == null).toList();

  List<CategoryData> getSubCategories(String parentId) =>
      categoryList.where((c) => c.parentId == parentId).toList();

  // ===================== FETCH =====================
  Future<void> fetchCategories() async {
    isLoading.value = true;
    try {
      final res = await ProductService.getCategories();
      if (res.statusCode == 200) {
        final jsonData = json.decode(res.body);
        categoryList.assignAll(
          (jsonData['data'] as List? ?? [])
              .map((e) => CategoryData.fromJson(e))
              .toList(),
        );
      }
    } catch (e) {
      AppToast.show('Gagal memuat kategori');
    } finally {
      isLoading.value = false;
    }
  }

  // ===================== CREATE =====================
  Future<String?> createCategory(String name, {String? parentId}) async {
    try {
      final res = await ProductService.createCategory(
        name: name,
        parentId: parentId,
      );
      if (res.statusCode == 201) {
        await fetchCategories();
        return json.decode(res.body)['data']['id'];
      } else {
        AppToast.show('Gagal tambah kategori');
      }
    } catch (e) {
      AppToast.show('Gagal tambah kategori');
    }
    return null;
  }

  // ===================== DELETE =====================
  Future<void> deleteCategory(String id) async {
    try {
      final res = await ProductService.deleteCategory(id);
      if (res.statusCode == 200) {
        categoryList.removeWhere((c) => c.id == id);
        AppToast.show('Kategori berhasil dihapus');
      } else {
        AppToast.show(ApiHelper.parseError(res.body));
      }
    } catch (e) {
      AppToast.show('Terjadi kesalahan');
    }
  }
}