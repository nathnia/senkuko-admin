import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:senkukoadmin/constant/app_colors.dart';
import 'package:senkukoadmin/constant/app_dialog.dart';
import 'package:senkukoadmin/features/products/controllers/product_image_controller.dart';
import 'package:senkukoadmin/features/products/controllers/product_controller.dart';
import 'package:senkukoadmin/features/products/models/product_image_model.dart';
import 'package:senkukoadmin/features/products/widgets/app_card.dart';

class ProductImageSection extends StatelessWidget {
  final ProductController controller;
  final String productId;
  final bool isAddMode;

  const ProductImageSection({
    super.key,
    required this.controller,
    required this.productId,
    this.isAddMode = false,
  });

  ProductImageController get _imageC => Get.find<ProductImageController>();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final List<ProductImageData> images = isAddMode
          ? _imageC.getPendingAsImageData()
          : [
              ..._imageC.getImagesForProduct(productId),
              ..._imageC.getPendingEditAsImageData(),
            ];

      final canAddMore = images.length < ProductImageController.maxImages;

      return AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──
            Row(
              children: [
                const Text(
                  'FOTO PRODUK',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.black54,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${images.length}/${ProductImageController.maxImages}',
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── Image list ──
            SizedBox(
              height: 100,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  ...images.asMap().entries.map((entry) {
                    final index = entry.key;
                    final image = entry.value;
                    final existingCount =
                        _imageC.getImagesForProduct(productId).length;
                    final isLocal =
                        isAddMode || index >= existingCount;

                    return _ImageThumb(
                      key: ValueKey(image.id.isEmpty ? 'local_$index' : image.id),
                      imageUrl: image.imageUrl,
                      isPrimary: image.isPrimary,
                      isLocal: isLocal,
                      imageC: _imageC,
                      onDelete: () => _handleDelete(
                        context: context,
                        image: image,
                        index: index,
                        existingCount: existingCount,
                      ),
                    );
                  }),
                  if (canAddMore)
                    _AddImageButton(
                      onTap: () => _showSourcePicker(context),
                    ),
                ],
              ),
            ),

            if (images.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Tap ✕ untuk hapus  •  Gambar pertama = foto utama',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                ),
              ),
          ],
        ),
      );
    });
  }

  // ── Delete handler — logic dikumpulkan di satu tempat ──
  Future<void> _handleDelete({
    required BuildContext context,
    required ProductImageData image,
    required int index,
    required int existingCount,
  }) async {
    // Add mode — hapus dari pending list
    if (isAddMode) {
      _imageC.removePendingImage(index);
      return;
    }

    // Edit mode, gambar belum diupload (pending)
    if (index >= existingCount) {
      _imageC.removePendingEditImage(index - existingCount);
      return;
    }

    // Edit mode, gambar sudah ada di server — perlu konfirmasi
    final confirm = await AppDialog.confirm(
      title: 'Hapus Gambar',
      content: 'Yakin ingin menghapus gambar ini?',
      confirmLabel: 'Hapus',
    );
    if (confirm) {
      controller.isDirty.value = true;
      _imageC.deleteProductImage(productId, image.id, index);
    }
  }

  // ── Satu method picker — isAddMode menentukan perilaku ──
  void _showSourcePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ImageSourceSheet(
        isAddMode: isAddMode,
        productId: productId,
        imageC: _imageC,
      ),
    );
  }
}

// ── Image thumbnail — widget tersendiri ───────────────────────────────────────
class _ImageThumb extends StatelessWidget {
  final String imageUrl;
  final bool isPrimary;
  final bool isLocal;
  final ProductImageController imageC;
  final VoidCallback onDelete;

  const _ImageThumb({
    super.key,
    required this.imageUrl,
    required this.isPrimary,
    required this.isLocal,
    required this.imageC,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) {
      return Container(
        width: 100,
        height: 100,
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(Icons.broken_image_outlined, color: Colors.grey.shade400),
      );
    }

    return Container(
      width: 100,
      height: 100,
      margin: const EdgeInsets.only(right: 8),
      child: Stack(
        children: [
          // ── Image ──
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: isLocal
                ? Image.file(
                    File(imageUrl),
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                  )
                : Image.network(
                    imageUrl,
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                    loadingBuilder: (_, child, progress) {
                      if (progress == null) return child;
                      return Container(
                        width: 100,
                        height: 100,
                        color: Colors.grey.shade100,
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                    },
                    errorBuilder: (_, __, ___) => Container(
                      width: 100,
                      height: 100,
                      color: Colors.grey.shade100,
                      child: Icon(
                        Icons.broken_image_outlined,
                        color: Colors.grey.shade400,
                        size: 28,
                      ),
                    ),
                  ),
          ),

          // ── Primary label ──
          if (isPrimary)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.24),
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(10),
                  ),
                ),
                child: const Text(
                  'Utama',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

          // ── Delete button — Obx kecil hanya untuk isUploadingImage ──
          Positioned(
            top: 4,
            right: 4,
            child: Obx(() {
              final isUploading = imageC.isUploadingImage.value;
              return GestureDetector(
                onTap: isUploading ? null : onDelete,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: isUploading ? Colors.grey.shade400 : Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

// ── Add image button ──────────────────────────────────────────────────────────
class _AddImageButton extends StatelessWidget {
  final VoidCallback onTap;

  const _AddImageButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate_outlined,
              size: 26,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 4),
            Text(
              'Tambah',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Bottom sheet — satu widget untuk add & edit mode ─────────────────────────
class _ImageSourceSheet extends StatelessWidget {
  final bool isAddMode;
  final String productId;
  final ProductImageController imageC;

  const _ImageSourceSheet({
    required this.isAddMode,
    required this.productId,
    required this.imageC,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Handle ──
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // ── Title — edit mode tampilkan counter ──
          if (isAddMode)
            const Text(
              'Tambah Foto',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            )
          else
            Obx(() => Text(
                  'Upload Gambar '
                  '(${imageC.getImagesForProduct(productId).length}'
                  '/${ProductImageController.maxImages})',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                )),
          const SizedBox(height: 16),

          // ── Pilihan source ──
          _sourceTile(
            icon: Icons.photo_library_outlined,
            label: 'Pilih dari Galeri',
            onTap: () {
              Get.back();
              if (isAddMode) {
                imageC.pickImageForNewProduct(source: ImageSource.gallery);
              } else {
                imageC.pickImageForEditProduct(
                  source: ImageSource.gallery,
                  productId: productId,
                );
              }
            },
          ),
          _sourceTile(
            icon: Icons.camera_alt_outlined,
            label: 'Ambil dari Kamera',
            onTap: () {
              Get.back();
              if (isAddMode) {
                imageC.pickImageForNewProduct(source: ImageSource.camera);
              } else {
                imageC.pickImageForEditProduct(
                  source: ImageSource.camera,
                  productId: productId,
                );
              }
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _sourceTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.primary, size: 18),
      ),
      title: Text(label, style: const TextStyle(fontSize: 14)),
      onTap: onTap,
    );
  }
}