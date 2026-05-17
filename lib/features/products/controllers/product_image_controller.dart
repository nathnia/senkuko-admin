// lib/features/products/controllers/product_image_controller.dart
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

  // ── Carousel state — taruh di sini biar StatelessWidget page tidak pegang state
  final carouselIndex = 0.obs;
  final carouselController = PageController();

  static const int maxImages = 5;

  // ===================== LIFECYCLE =====================
  @override
  void onClose() {
    carouselController.dispose();
    super.onClose();
  }

  // ===================== HELPERS =====================

  // bool _isNetworkError(response) =>
  //     response.statusCode == 408 || response.statusCode == 503;

  // String _parseMessage(String body) {
  //   try {
  //     return json.decode(body)['message'] ?? 'Terjadi kesalahan';
  //   } catch (_) {
  //     return 'Terjadi kesalahan';
  //   }
  // }

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

  List<ProductImageData> getImagesForProduct(String productId) {
    return allProductImages[productId] ?? [];
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
        AppToast.error(ApiHelper.parseError(res.body));
        return;
      }

      if (res.statusCode == 200 || res.statusCode == 204) {
        _removeImageLocally(productId, index);
        AppToast.success('Gambar berhasil dihapus');
      } else {
        AppToast.error('Gagal menghapus gambar (${res.statusCode})');
      }
    } catch (e) {
      AppToast.error('Terjadi kesalahan saat menghapus gambar');
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

  // ===================== PICK FOR EDIT =====================
  Future<void> pickImageForEditProduct({
    ImageSource source = ImageSource.gallery,
    required String productId,
  }) async {
    final existingCount = getImagesForProduct(productId).length;
    if (existingCount + pendingEditImages.length >= maxImages) {
      AppToast.warning('Maksimal $maxImages gambar per produk');
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
        AppToast.warning('Gunakan JPEG, PNG, atau WEBP');
        return;
      }

      pendingEditImages.add(pickedFile);
      Get.find<ProductController>().isDirty.value = true;
    } catch (e) {
      AppToast.error('Gagal memilih gambar');
    }
  }

  // ===================== UPLOAD PENDING EDIT =====================
  Future<void> uploadPendingEditImages(String productId) async {
    if (pendingEditImages.isEmpty) return;

    int failCount = 0;

    for (var image in List<XFile>.from(pendingEditImages)) {
      try {
        final bytes = await image.readAsBytes();
        final res = await ProductService.uploadProductImage(
          productId: productId,
          imageBytes: bytes,
          fileName: image.name,
        );

        if (ApiHelper.isNetworkError(res)) {
          AppToast.error(ApiHelper.parseError(res.body));
          break;
        } else if (res.statusCode != 200 && res.statusCode != 201) {
          failCount++;
        }
      } catch (e) {
        failCount++;
      }
    }

    pendingEditImages.clear();
    isUploadingImage.value = false;

    if (failCount > 0) {
      AppToast.warning('$failCount gambar gagal diupload');
    }
  }

  void removePendingEditImage(int index) {
    if (index < 0 || index >= pendingEditImages.length) return;
    pendingEditImages.removeAt(index);
  }

  // ===================== PENDING AS IMAGE DATA =====================
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

  void removePendingImage(int index) {
    if (index < 0 || index >= pendingImages.length) return;
    pendingImages.removeAt(index);
  }

  // ===================== PICK FOR NEW PRODUCT =====================
  Future<void> pickImageForNewProduct({
    ImageSource source = ImageSource.gallery,
  }) async {
    if (pendingImages.length >= maxImages) {
      AppToast.warning('Maksimal $maxImages gambar per produk');
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
        AppToast.warning('Gunakan JPEG, PNG, atau WEBP');
        return;
      }

      pendingImages.add(pickedFile);
      Get.find<ProductController>().isDirty.value = true;
    } catch (e) {
      AppToast.error('Gagal memilih gambar');
    }
  }

  // ===================== UPLOAD PENDING (add mode) =====================
  Future<void> uploadPendingImages(String productId) async {
    if (pendingImages.isEmpty) return;

    int failCount = 0;

    for (var image in List<XFile>.from(pendingImages)) {
      try {
        final bytes = await image.readAsBytes();
        final res = await ProductService.uploadProductImage(
          productId: productId,
          imageBytes: bytes,
          fileName: image.name,
        );

        if (res.statusCode == 200 || res.statusCode == 201) {
        } else if (ApiHelper.isNetworkError(res)) {
          AppToast.error(ApiHelper.parseError(res.body));
          break;
        } else {
          failCount++;
        }
      } catch (e) {
        failCount++;
      }
    }

    pendingImages.clear();
    isUploadingImage.value = false;

    if (failCount > 0) {
      AppToast.warning('$failCount gambar gagal diupload');
    }
  }
}