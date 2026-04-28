import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:senkukoadmin/features/products/models/product_image_model.dart';
import 'package:senkukoadmin/features/products/product_service.dart';

class ProductImageController extends GetxController {
  final isUploadingImage = false.obs;
  final pendingImages = <XFile>[].obs;
  final allProductImages = <String, List<ProductImageData>>{}.obs;

  static const int maxImages = 5;

  // ===================== FETCH =====================
  Future<void> fetchProductImages(String productId) async {
    final res = await ProductService.getProductImages(productId);
    if (res.statusCode != 200) return;

    final jsonData = json.decode(res.body);
    final List raw = jsonData['data'] ?? [];

    allProductImages[productId] = raw
        .map((e) => ProductImageData.fromJson(e as Map<String, dynamic>))
        .toList();

    // ← tambah ini sementara
    debugPrint("Images for $productId:");
    for (var img in allProductImages[productId]!) {
      debugPrint("  id: '${img.id}' | publicId: '${img.publicId}'");
    }

    allProductImages.refresh();
  }

  // Helper getter:
  List<ProductImageData> getImagesForProduct(String productId) {
    return allProductImages[productId] ?? [];
  }

  // ===================== DELETE IMAGE =====================
  Future<void> deleteProductImage(
    String productId,
    String publicId,
    int index,
  ) async {
    if (publicId.isEmpty) {
      _removeImageLocally(productId, index);
      return;
    }
    isUploadingImage.value = true;
    try {
      final res = await ProductService.deleteProductImage(productId, publicId)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw TimeoutException("timeout"),
          );
      if (res.statusCode == 200 || res.statusCode == 204) {
        _removeImageLocally(productId, index);
        Get.snackbar(
          "Sukses",
          "Gambar berhasil dihapus",
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        Get.snackbar(
          "Gagal",
          "Gagal menghapus gambar (${res.statusCode})",
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } on TimeoutException {
      Get.snackbar(
        "Timeout",
        "Request terlalu lama, coba lagi",
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        "Error",
        e.toString(),
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isUploadingImage.value = false;
    }
  }

  void _removeImageLocally(String productId, int index) {
    final current = allProductImages[productId] ?? [];
    if (index < 0 || index >= current.length) return;

    // ✅ SEDERHANAKAN - Hapus langsung tanpa mapping ulang
    final updated = List<ProductImageData>.from(current);
    updated.removeAt(index);

    if (updated.isEmpty) {
      allProductImages.remove(productId);
    } else {
      // ✅ Set gambar pertama sebagai primary (jika diperlukan)
      if (updated[0].isPrimary == false) {
        updated[0] = updated[0].copyWith(isPrimary: true);
      }
      allProductImages[productId] = updated;
    }

    allProductImages.refresh();
  }

  String _parseErrorMessage(String body) {
    try {
      return json.decode(body)['message'] ?? 'Terjadi kesalahan';
    } catch (_) {
      return 'Terjadi kesalahan';
    }
  }

  Future<void> pickAndUploadImage(String productId) async {
    if (getImagesForProduct(productId).length >= maxImages) {
      Get.snackbar('Batas Tercapai', 'Maksimal $maxImages gambar per produk');
      return;
    }

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (pickedFile == null) return;

    final ext = pickedFile.name.split('.').last.toLowerCase();
    if (!['jpg', 'jpeg', 'png', 'webp'].contains(ext)) {
      Get.snackbar('Format Tidak Valid', 'Gunakan JPEG, PNG, atau WEBP');
      return;
    }

    isUploadingImage.value = true;

    try {
      final bytes = await pickedFile.readAsBytes();

      final res = await ProductService.uploadProductImage(
        productId: productId,
        imageBytes: bytes,
        fileName: pickedFile.name,
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        final decoded = json.decode(res.body);

        String imageUrl =
            decoded['image_url']?.toString() ??
            decoded['data']?['image_url']?.toString() ??
            '';

        if (imageUrl.isEmpty) {
          Get.snackbar('Gagal', 'URL gambar tidak ditemukan');
          return;
        }

        final current = allProductImages[productId] ?? [];
        allProductImages[productId] = [
          ...current,
          ProductImageData(
            id: '',
            productId: productId,
            imageUrl: imageUrl,
            publicId: decoded['public_id']?.toString() ?? '',
            isPrimary: current.isEmpty,
            createdAt: DateTime.now(),
          ),
        ];

        allProductImages.refresh();

        Get.snackbar(
          'Sukses',
          'Gambar berhasil diupload (${getImagesForProduct(productId).length}/$maxImages)',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        Get.snackbar('Gagal Upload', _parseErrorMessage(res.body));
      }
    } catch (e) {
      Get.snackbar('Error', 'Gagal upload gambar');
    } finally {
      isUploadingImage.value = false;
    }
  }

  // 1. Untuk ADD product - simpan dulu ke local, belum upload
  Future<void> pickImageForNewProduct() async {
    if (pendingImages.length >= maxImages) {
      Get.snackbar('Batas Tercapai', 'Maksimal $maxImages gambar per produk');
      return;
    }

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (pickedFile == null) return;

    final ext = pickedFile.name.split('.').last.toLowerCase();
    if (!['jpg', 'jpeg', 'png', 'webp'].contains(ext)) {
      Get.snackbar('Format Tidak Valid', 'Gunakan JPEG, PNG, atau WEBP');
      return;
    }

    pendingImages.add(pickedFile);
  }

  Future<void> uploadPendingImages(String productId) async {
    for (var image in pendingImages) {
      isUploadingImage.value = true;
      try {
        final bytes = await image.readAsBytes();
        await ProductService.uploadProductImage(
          productId: productId,
          imageBytes: bytes,
          fileName: image.name,
        );
      } catch (e) {
        debugPrint('ERROR upload pending image: $e');
      }
    }
    pendingImages.clear();
    isUploadingImage.value = false;
  }
}
