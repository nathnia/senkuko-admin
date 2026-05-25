// lib/features/products/widgets/product_info_form.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:senkukoadmin/constant/app_colors.dart';
import 'package:senkukoadmin/constant/app_textfield.dart';
import 'package:senkukoadmin/features/products/controllers/category_controller.dart';
import 'package:senkukoadmin/features/products/controllers/product_controller.dart';
import 'package:senkukoadmin/features/products/widgets/app_card.dart';

class ProductInfoForm {
  final ProductController controller;
  final CategoryController categoryC = Get.find<CategoryController>();

  ProductInfoForm(this.controller);

  Widget productForm() {
    return AppCard(
      title: 'INFORMASI PRODUK',
      child: Column(
        children: [
          AppTextField(
            label: 'Nama Produk',
            hint: 'cth: Indomie Goreng',
            controller: controller.nameC,
          ),
          AppTextField(
            label: 'SKU Code',
            hint: 'cth: PRD-001',
            controller: controller.skuC,
          ),
          AppTextField(
            label: 'Deskripsi',
            hint: 'Tambahkan Deskripsi',
            controller: controller.descC,
            maxLines: 3,
          ),
          AppTextField(
            label: 'Barcode',
            hint: 'cth: 8999999004001',
            controller: controller.barcodeC,
          ),
          const SizedBox(height: 4),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Kategori',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.subtext,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 5),
              categorySelector(),
            ],
          ),
        ],
      ),
    );
  }

  // ================= CATEGORY SELECTOR =================
  Widget categorySelector() {
    return Obx(() {
      final selected = categoryC.categoryList.firstWhereOrNull(
        (c) => c.id == controller.selectedCategoryId.value,
      );

      String displayName = 'Pilih Kategori';
      if (selected != null) {
        displayName = selected.parentName != null
            ? '${selected.parentName} › ${selected.name}'
            : selected.name;
      }

      return GestureDetector(
        onTap: _openCategorySheet,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  displayName,
                  style: TextStyle(
                    fontSize: 14,
                    color: selected != null
                        ? Colors.black87
                        : AppColors.subtext,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_drop_down_rounded,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      );
    });
  }

  // ================= BOTTOM SHEET =================
  void _openCategorySheet() {
    final searchC = TextEditingController();
    final searchQuery = ''.obs;

    showModalBottomSheet(
      context: Get.context!,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              _buildHeader(searchC, searchQuery),
              Expanded(
                child: Obx(() {
                  final query = searchQuery.value;
                  final parents = categoryC.parentCategories;

                  if (parents.isEmpty) {
                    return _buildEmptyState();
                  }

                  // Mode search — tampil flat
                  if (query.isNotEmpty) {
                    final filtered = categoryC.categoryList
                        .where(
                          (c) =>
                              c.name.toLowerCase().contains(query) ||
                              (c.parentName
                                      ?.toLowerCase()
                                      .contains(query) ??
                                  false),
                        )
                        .toList();

                    if (filtered.isEmpty) {
                      return Center(
                        child: Text(
                          'Kategori tidak ditemukan',
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 13,
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      controller: scrollController,
                      itemCount: filtered.length,
                      itemBuilder: (context, i) {
                        final cat = filtered[i];
                        return _categoryTile(
                          name: cat.parentName != null
                              ? '${cat.parentName} › ${cat.name}'
                              : cat.name,
                          onTap: () => _selectCategory(cat.id),
                        );
                      },
                    );
                  }

                  // Mode normal — grouped
                  return ListView.builder(
                    controller: scrollController,
                    itemCount: parents.length,
                    itemBuilder: (context, i) {
                      final parent = parents[i];
                      final subs = categoryC.getSubCategories(parent.id);
                      return _buildGroup(parent.name, subs.map((s) {
                        return _categoryTile(
                          name: s.name,
                          isSubCategory: true,
                          onTap: () => _selectCategory(s.id),
                        );
                      }).toList());
                    },
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _selectCategory(String id) {
    controller.selectedCategoryId.value = id;
    controller.checkDirty();
    Get.back();
  }

  // ================= WIDGETS =================
  Widget _buildHeader(
    TextEditingController searchC,
    RxString searchQuery,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        children: [
          _bottomSheetHandle(),
          const SizedBox(height: 14),
          const Text(
            'Pilih Kategori',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: searchC,
            onChanged: (v) => searchQuery.value = v.toLowerCase(),
            decoration: InputDecoration(
              hintText: 'Cari kategori...',
              hintStyle: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade400,
              ),
              prefixIcon: Icon(
                Icons.search_rounded,
                color: Colors.grey.shade400,
                size: 20,
              ),
              filled: true,
              fillColor: Colors.grey.shade100,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildGroup(String parentName, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text(
            parentName.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade400,
              letterSpacing: 0.5,
            ),
          ),
        ),
        ...children,
        const Divider(height: 1, indent: 16, endIndent: 16),
      ],
    );
  }

  Widget _categoryTile({
    required String name,
    required VoidCallback onTap,
    bool isSubCategory = false,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.only(
        left: isSubCategory ? 32 : 16,
        right: 16,
      ),
      title: Text(name, style: const TextStyle(fontSize: 14)),
      onTap: onTap,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Text(
        'Belum ada kategori',
        style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
      ),
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