// lib/features/products/widgets/product_image_section.dart
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

  ProductImageController get imageC => Get.find<ProductImageController>();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final List<ProductImageData> images;
      if (isAddMode) {
        images = imageC.getPendingAsImageData();
      } else {
        images = [
          ...imageC.getImagesForProduct(productId),
          ...imageC.getPendingEditAsImageData(),
        ];
      }

      final canAddMore = images.length < ProductImageController.maxImages;

      return AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            SizedBox(
              height: 100,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  ...images.asMap().entries.map((entry) {
                    final int index = entry.key;
                    final ProductImageData image = entry.value;

                    return _imageThumb(
                      imageUrl: image.imageUrl,
                      isPrimary: image.isPrimary,
                      isLocal: isAddMode ||
                          (!isAddMode &&
                              index >=
                                  imageC
                                      .getImagesForProduct(productId)
                                      .length),
                      onDelete: () async {
                        if (isAddMode) {
                          imageC.removePendingImage(index);
                          return;
                        }

                        final currentExistingCount =
                            imageC.getImagesForProduct(productId).length;
                        final isPendingEditNow = index >= currentExistingCount;

                        if (isPendingEditNow) {
                          imageC.removePendingEditImage(
                            index - currentExistingCount,
                          );
                          return;
                        }

                        final confirm = await AppDialog.confirm(
                          title: 'Hapus Gambar',
                          content: 'Yakin ingin menghapus gambar ini?',
                          confirmLabel: 'Hapus',
                        );
                        if (confirm) {
                          controller.isDirty.value = true;
                          imageC.deleteProductImage(
                            productId,
                            image.id,
                            index,
                          );
                        }
                      },
                    );
                  }),
                  if (canAddMore) _addImageButton(context),
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

  // ================= IMAGE THUMBNAIL =================
  Widget _imageThumb({
    required String imageUrl,
    required bool isPrimary,
    required VoidCallback onDelete,
    bool isLocal = false,
  }) {
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
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        width: 100,
                        height: 100,
                        color: Colors.grey.shade100,
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) => Container(
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
          if (isPrimary)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(60),
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
          Positioned(
            top: 4,
            right: 4,
            child: Obx(
              () => GestureDetector(
                onTap: imageC.isUploadingImage.value ? null : onDelete,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: imageC.isUploadingImage.value
                        ? Colors.grey.shade400
                        : Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================= ADD IMAGE BUTTON =================
  Widget _addImageButton(BuildContext context) {
    return GestureDetector(
      onTap: () => isAddMode
          ? _showAddImageSourcePicker(context)
          : _showImageSourcePicker(context),
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

  // ================= IMAGE SOURCE PICKERS =================
  void _showImageSourcePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _bottomSheetHandle(),
            const SizedBox(height: 16),
            Obx(
              () => Text(
                'Upload Gambar (${imageC.getImagesForProduct(productId).length}/${ProductImageController.maxImages})',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _imageSourceTile(
              icon: Icons.photo_library_outlined,
              label: 'Pilih dari Galeri',
              onTap: () {
                Get.back();
                imageC.pickImageForEditProduct(
                  source: ImageSource.gallery,
                  productId: productId,
                );
              },
            ),
            _imageSourceTile(
              icon: Icons.camera_alt_outlined,
              label: 'Ambil dari Kamera',
              onTap: () {
                Get.back();
                imageC.pickImageForEditProduct(
                  source: ImageSource.camera,
                  productId: productId,
                );
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showAddImageSourcePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _bottomSheetHandle(),
            const SizedBox(height: 16),
            const Text(
              'Tambah Foto',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
            const SizedBox(height: 16),
            _imageSourceTile(
              icon: Icons.photo_library_outlined,
              label: 'Pilih dari Galeri',
              onTap: () {
                Get.back();
                imageC.pickImageForNewProduct(source: ImageSource.gallery);
              },
            ),
            _imageSourceTile(
              icon: Icons.camera_alt_outlined,
              label: 'Ambil dari Kamera',
              onTap: () {
                Get.back();
                imageC.pickImageForNewProduct(source: ImageSource.camera);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _imageSourceTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.primary.withAlpha(15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.primary, size: 18),
      ),
      title: Text(label, style: const TextStyle(fontSize: 14)),
      onTap: onTap,
    );
  }

  Widget _bottomSheetHandle() {
    return Container(
      width: 36,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}