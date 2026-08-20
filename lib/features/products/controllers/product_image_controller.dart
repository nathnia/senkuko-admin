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

  // ===================== ORDERING =====================
  // Endpoint list produk (getProducts) nggak ngirim field created_at/id
  // per gambar sama sekali — cuma url & is_primary (yang is_primary-nya
  // sendiri selalu false, nggak kepake). Satu-satunya sinyal urutan
  // upload yang konsisten ada di URL Cloudinary itu sendiri: segmen
  // setelah "/upload/v" adalah version number, yang defaultnya = unix
  // timestamp saat file diupload. Dipakai sebagai pengganti createdAt
  // buat nentuin urutan "gambar pertama" secara stabil, apapun urutan
  // mentah yang dibalikin backend (endpoint list vs endpoint detail
  // gambar bisa beda urutan array-nya).
  //
  // "Gambar utama" di UI ditentukan MURNI dari index ke-0 hasil sort
  // ini — bukan dari field is_primary (yang emang nggak reliable dari
  // backend saat ini).
  int _cloudinaryVersion(String url) {
    final match = RegExp(r'/upload/v(\d+)/').firstMatch(url);
    if (match == null) return 0;
    return int.tryParse(match.group(1)!) ?? 0;
  }

  List<ProductImageData> _sortByUploadOrder(List<ProductImageData> images) {
    final sorted = List<ProductImageData>.from(images);
    sorted.sort(
      (a, b) =>
          _cloudinaryVersion(a.imageUrl).compareTo(_cloudinaryVersion(b.imageUrl)),
    );
    return sorted;
  }

  // ===================== CACHE =====================
  void clearAllCache() {
    allProductImages.clear();
    allProductImages.refresh();
  }

  // Replace semua cache sekaligus — atomic, tidak ada flicker.
  // CHANGED: sort by Cloudinary upload version dulu sebelum masuk
  // cache, biar konsisten walau sumbernya endpoint list produk (yang
  // urutan array-nya kadang naruh gambar terbaru di depan).
  void replaceAllCache(Map<String, List<ProductImageData>> newCache) {
    final sorted = newCache.map(
      (key, value) => MapEntry(key, _sortByUploadOrder(value)),
    );
    allProductImages.assignAll(sorted);
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

      final images = raw
          .map((e) => ProductImageData.fromJson(e as Map<String, dynamic>))
          .toList();

      // CHANGED: paksa urutan konsisten sama jalur endpoint list produk.
      allProductImages[productId] = _sortByUploadOrder(images);

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

      final images = raw
          .map((e) => ProductImageData.fromJson(e as Map<String, dynamic>))
          .toList();

      // CHANGED: sort juga di jalur ini biar konsisten.
      target[productId] = _sortByUploadOrder(images);
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

  // Primary di UI otomatis ngikut index 0 setelah item dihapus — nggak
  // perlu manual re-flag apapun di sini, karena badge "Utama" murni
  // dari posisi array (lihat ProductImageSection).
  void _removeImageLocally(String productId, int index) {
    final current = allProductImages[productId] ?? [];
    if (index < 0 || index >= current.length) return;

    final updated = List<ProductImageData>.from(current);
    updated.removeAt(index);

    if (updated.isEmpty) {
      allProductImages.remove(productId);
    } else {
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

  // NOTE: isPrimary di sini udah nggak dipakai buat nentuin badge
  // "Utama" (itu sekarang murni dari index di UI). Field-nya cuma
  // dipertahankan karena ProductImageData butuh nilai non-null.
  List<ProductImageData> getPendingAsImageData() {
    return pendingImages.asMap().entries.map((entry) {
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

    // Snapshot supaya aman diiterasi walau `images` (list reaktif asli)
    // berubah di tengah proses (misal user menambah gambar baru).
    final snapshot = List<XFile>.from(images);

    for (var image in snapshot) {
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
          debugPrint(
            'Upload gagal — status: ${res.statusCode}, body: ${res.body}',
          );
          failCount++;
        } else {
          // Sukses — hapus item ini saja dari list asli.
          images.remove(image);
        }
      } catch (e) {
        failCount++;
      }
    }

    if (failCount > 0) {
      AppToast.show('$failCount gambar gagal diupload');
    }
  }

  // ===================== PICK — PUBLIC =====================
  Future<void> pickImageForNewProduct({
    ImageSource source = ImageSource.gallery,
  }) => _pickImage(source: source, isEditMode: false);

  Future<void> pickImageForEditProduct({
    ImageSource source = ImageSource.gallery,
    required String productId,
  }) => _pickImage(source: source, isEditMode: true, productId: productId);

  // ===================== UPLOAD — PUBLIC =====================
  Future<void> uploadPendingImages(String productId) async {
    isUploadingImage.value = true;
    try {
      await _uploadImages(pendingImages, productId);
    } finally {
      isUploadingImage.value = false;
    }
  }

  Future<void> uploadPendingEditImages(String productId) async {
    isUploadingImage.value = true;
    try {
      await _uploadImages(pendingEditImages, productId);
    } finally {
      isUploadingImage.value = false;
    }
  }
}