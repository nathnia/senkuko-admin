import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:senkukoadmin/constant/api_helper.dart';
import 'package:senkukoadmin/constant/app_toast.dart';
import 'package:senkukoadmin/features/products/controllers/product_controller.dart';
import 'package:senkukoadmin/features/products/models/product_image_model.dart';
import 'package:senkukoadmin/features/products/product_service.dart';

class ProductImageController extends GetxController {
  final isUploadingImage = false.obs;
  final pendingImages = <XFile>[].obs;
  final pendingEditImages = <XFile>[].obs;
  final allProductImages = <String, List<ProductImageData>>{}.obs;

  // ── Carousel state
  final carouselIndex = 0.obs;
  final carouselController = PageController();

  static const int maxImages = 5;

  // ===================== LIFECYCLE =====================
  @override
  void onClose() {
    carouselController.dispose();
    super.onClose();
  }

  // ===================== CACHE =====================
  void clearAllCache() {
    allProductImages.clear();
    allProductImages.refresh();
  }

  // Replace semua cache sekaligus — atomic, tidak ada flicker
  void replaceAllCache(Map<String, List<ProductImageData>> newCache) {
    allProductImages.assignAll(newCache);
    allProductImages.refresh();
  }

  List<ProductImageData> getImagesForProduct(String productId) {
    return allProductImages[productId] ?? [];
  }

  // ===================== FETCH =====================
  Future<void> fetchProductImages(String productId) async {
    try {
      final res = await ProductService.getProductImages(productId);
      if (res.statusCode != 200) return;

      final jsonData = json.decode(res.body);
      final List raw = jsonData['data'] ?? [];

      allProductImages[productId] = raw
          .map((e) => ProductImageData.fromJson(e as Map<String, dynamic>))
          .toList();

      allProductImages.refresh();
    } catch (_) {}
  }

  // Fetch ke map sementara — tidak langsung update allProductImages
  // Dipakai oleh fetchProducts() untuk atomic cache replacement
  Future<void> fetchProductImagesInto(
    String productId,
    Map<String, List<ProductImageData>> target,
  ) async {
    try {
      final res = await ProductService.getProductImages(productId);
      if (res.statusCode != 200) return;

      final jsonData = json.decode(res.body);
      final List raw = jsonData['data'] ?? [];

      target[productId] = raw
          .map((e) => ProductImageData.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {}
  }

  // ===================== DELETE IMAGE =====================
  Future<void> deleteProductImage(
    String productId,
    String imageId,
    int index,
  ) async {
    if (imageId.isEmpty) {
      _removeImageLocally(productId, index);
      return;
    }

    isUploadingImage.value = true;
    try {
      final res = await ProductService.deleteProductImage(productId, imageId);

      if (ApiHelper.isNetworkError(res)) {
        AppToast.show(ApiHelper.parseError(res.body));
        return;
      }

      if (res.statusCode == 200 || res.statusCode == 204) {
        _removeImageLocally(productId, index);
        AppToast.show('Gambar berhasil dihapus');
      } else {
        AppToast.show('Gagal menghapus gambar (${res.statusCode})');
      }
    } catch (e) {
      AppToast.show('Terjadi kesalahan saat menghapus gambar');
    } finally {
      isUploadingImage.value = false;
    }
  }

  void _removeImageLocally(String productId, int index) {
    final current = allProductImages[productId] ?? [];
    if (index < 0 || index >= current.length) return;

    final updated = List<ProductImageData>.from(current);
    updated.removeAt(index);

    if (updated.isEmpty) {
      allProductImages.remove(productId);
    } else {
      if (!updated[0].isPrimary) {
        updated[0] = updated[0].copyWith(isPrimary: true);
      }
      allProductImages[productId] = updated;
    }

    allProductImages.refresh();
  }

  // ===================== PENDING HELPERS =====================
  void removePendingImage(int index) {
    if (index < 0 || index >= pendingImages.length) return;
    pendingImages.removeAt(index);
  }

  void removePendingEditImage(int index) {
    if (index < 0 || index >= pendingEditImages.length) return;
    pendingEditImages.removeAt(index);
  }

  List<ProductImageData> getPendingAsImageData() {
    return pendingImages.asMap().entries.map((entry) {
      return ProductImageData(
        id: '',
        productId: '',
        imageUrl: entry.value.path,
        publicId: '',
        isPrimary: entry.key == 0,
        createdAt: DateTime.now(),
      );
    }).toList();
  }

  List<ProductImageData> getPendingEditAsImageData() {
    return pendingEditImages.asMap().entries.map((entry) {
      return ProductImageData(
        id: '',
        productId: '',
        imageUrl: entry.value.path,
        publicId: '',
        isPrimary: false,
        createdAt: DateTime.now(),
      );
    }).toList();
  }

  // ===================== PRIVATE SHARED LOGIC =====================
  Future<void> _pickImage({
    required ImageSource source,
    required bool isEditMode,
    String? productId,
  }) async {
    final existingCount = isEditMode
        ? getImagesForProduct(productId!).length + pendingEditImages.length
        : pendingImages.length;

    if (existingCount >= maxImages) {
      AppToast.show('Maksimal $maxImages gambar per produk');
      return;
    }

    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (pickedFile == null) return;

      final ext = pickedFile.name.split('.').last.toLowerCase();
      if (!['jpg', 'jpeg', 'png', 'webp'].contains(ext)) {
        AppToast.show('Gunakan JPEG, PNG, atau WEBP');
        return;
      }

      if (isEditMode) {
        pendingEditImages.add(pickedFile);
      } else {
        pendingImages.add(pickedFile);
      }

      Get.find<ProductController>().checkDirty();
    } catch (e) {
      AppToast.show('Gagal memilih gambar');
    }
  }

  Future<void> _uploadImages(List<XFile> images, String productId) async {
    if (images.isEmpty) return;

    int failCount = 0;

    for (var image in List<XFile>.from(images)) {
      try {
        final bytes = await image.readAsBytes();
        final res = await ProductService.uploadProductImage(
          productId: productId,
          imageBytes: bytes,
          fileName: image.name,
        );

        if (ApiHelper.isNetworkError(res)) {
          AppToast.show(ApiHelper.parseError(res.body));
          break;
        } else if (res.statusCode != 200 && res.statusCode != 201) {
          failCount++;
        }
      } catch (e) {
        failCount++;
      }
    }

    isUploadingImage.value = false;

    if (failCount > 0) {
      AppToast.show('$failCount gambar gagal diupload');
    }
  }

  // ===================== PICK — PUBLIC =====================
  Future<void> pickImageForNewProduct({
    ImageSource source = ImageSource.gallery,
  }) =>
      _pickImage(source: source, isEditMode: false);

  Future<void> pickImageForEditProduct({
    ImageSource source = ImageSource.gallery,
    required String productId,
  }) =>
      _pickImage(source: source, isEditMode: true, productId: productId);

  // ===================== UPLOAD — PUBLIC =====================
  Future<void> uploadPendingImages(String productId) async {
    await _uploadImages(pendingImages, productId);
    pendingImages.clear();
  }

  Future<void> uploadPendingEditImages(String productId) async {
    await _uploadImages(pendingEditImages, productId);
    pendingEditImages.clear();
  }
}