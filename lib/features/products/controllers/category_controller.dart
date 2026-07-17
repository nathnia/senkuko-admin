import 'dart:convert';
import 'package:get/get.dart';
import 'package:senkukoadmin/constant/api_helper.dart';
import 'package:senkukoadmin/constant/app_toast.dart';
import 'package:senkukoadmin/constant/cache_service.dart';
import 'package:senkukoadmin/features/products/models/category_model.dart';
import 'package:senkukoadmin/features/products/product_service.dart';

class CategoryController extends GetxController {
  final categoryList = <CategoryData>[].obs;
  final isLoading = false.obs;
  final hasError = false.obs;

  // ===================== GETTERS =====================
  List<CategoryData> get parentCategories =>
      categoryList.where((c) => c.parentId == null).toList();

  List<CategoryData> getSubCategories(String parentId) =>
      categoryList.where((c) => c.parentId == parentId).toList();

  // ===================== LOOKUP HELPERS =====================
  CategoryData? findByName(String name) {
    if (name.isEmpty) return null;
    return categoryList.firstWhereOrNull(
      (c) => c.name.toLowerCase() == name.toLowerCase(),
    );
  }

  String? resolveParentName(String categoryName) {
    final cat = findByName(categoryName);
    if (cat == null) return null;
    if (cat.parentId == null) return cat.name;
    final parent = categoryList.firstWhereOrNull((c) => c.id == cat.parentId);
    return parent?.name;
  }

  // ===================== FETCH =====================
  /// forceRefresh=true skip cache — dipakai setelah create/delete.
  Future<void> fetchCategories({bool forceRefresh = false}) async {
    if (isLoading.value) return;

    // Cache-first: render instant kalau ada & masih fresh.
    if (!forceRefresh) {
      final cached = CacheService.instance.get(
        CacheKeys.categories,
        ttl: CacheKeys.referenceDataTtl,
      );
      if (cached != null) {
        categoryList.assignAll(
          (cached as List).map((e) => CategoryData.fromJson(e)).toList(),
        );
        return; // cache masih valid, gak perlu network sama sekali
      }
    }

    isLoading.value = true;
    hasError.value = false;
    try {
      final res = await ProductService.getCategories();
      if (res.statusCode == 200) {
        final jsonData = json.decode(res.body);
        final list = (jsonData['data'] as List? ?? [])
            .map((e) => CategoryData.fromJson(e))
            .toList();
        categoryList.assignAll(list);
        await CacheService.instance.set(
          CacheKeys.categories,
          list.map((c) => c.toJson()).toList(),
        );
      } else {
        hasError.value = true;
      }
    } catch (e) {
      hasError.value = true;
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
        await CacheService.instance.invalidate(CacheKeys.categories);
        await fetchCategories(forceRefresh: true);
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
        await CacheService.instance.invalidate(CacheKeys.categories);
        AppToast.show('Kategori berhasil dihapus');
      } else {
        AppToast.show(ApiHelper.parseError(res.body));
      }
    } catch (e) {
      AppToast.show('Terjadi kesalahan');
    }
  }
}