// FILE: lib/features/products/pages/manage_categories_page.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:senkukoadmin/constant/app_colors.dart';
import 'package:senkukoadmin/constant/app_dialog.dart';
import 'package:senkukoadmin/features/products/controllers/category_controller.dart';
import 'package:senkukoadmin/features/products/models/category_model.dart';
import 'package:senkukoadmin/features/products/widgets/add_category_sheet.dart';

class ManageCategoriesPage extends StatelessWidget {
  const ManageCategoriesPage({super.key});

  CategoryController get _categoryC => Get.find<CategoryController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
            color: Colors.black87,
          ),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Kelola Kategori',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
      ),
      body: Obx(() {
        if (_categoryC.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final parents = _categoryC.parentCategories;

        if (parents.isEmpty) {
          return _EmptyState(onAdd: () => _openAddSheet(context));
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
          itemCount: parents.length,
          itemBuilder: (context, i) {
            final parent = parents[i];
            final children = _categoryC.getSubCategories(parent.id);
            return _CategoryGroup(
              parent: parent,
              children: children,
              onDeleteParent: () => _confirmDelete(context, parent),
              onDeleteChild: (child) => _confirmDelete(context, child),
            );
          },
        );
      }),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddSheet(context),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 2,
        icon: const Icon(Icons.add_rounded, size: 20),
        label: const Text(
          'Tambah',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  void _openAddSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddCategorySheet(categoryC: _categoryC),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    CategoryData category,
  ) async {
    final hasChildren = _categoryC.getSubCategories(category.id).isNotEmpty;

    final confirmed = await AppDialog.confirm(
      title: 'Hapus Kategori',
      content: hasChildren
          ? 'Menghapus "${category.name}" juga akan menghapus semua sub-kategorinya. Lanjutkan?'
          : 'Yakin ingin menghapus "${category.name}"?',
      confirmLabel: 'Ya, Hapus',
    );

    if (!confirmed) return;

    if (hasChildren) {
      for (final child in _categoryC.getSubCategories(category.id)) {
        await _categoryC.deleteCategory(child.id);
      }
    }

    await _categoryC.deleteCategory(category.id);
  }
}

// ═══════════════════════════════════════════════════════════════
// CATEGORY GROUP
// One card per parent group. Children are rows inside the same
// card — visually grouped, not floating separately.
// ═══════════════════════════════════════════════════════════════
class _CategoryGroup extends StatelessWidget {
  final CategoryData parent;
  final List<CategoryData> children;
  final VoidCallback onDeleteParent;
  final void Function(CategoryData) onDeleteChild;

  const _CategoryGroup({
    required this.parent,
    required this.children,
    required this.onDeleteParent,
    required this.onDeleteChild,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          // ── Parent row ──
          _ParentRow(
            name: parent.name,
            childCount: children.length,
            onDelete: onDeleteParent,
          ),

          // ── Children — divider + indented rows inside the same card ──
          if (children.isNotEmpty) ...[
            Divider(height: 1, color: Colors.grey.shade100),
            ...children.map(
              (c) => _ChildRow(
                name: c.name,
                onDelete: () => onDeleteChild(c),
                isLast: c == children.last,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Parent row ───────────────────────────────────────────────────
class _ParentRow extends StatelessWidget {
  final String name;
  final int childCount;
  final VoidCallback onDelete;

  const _ParentRow({
    required this.name,
    required this.childCount,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(20),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.folder_copy_rounded,
              size: 15,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                if (childCount > 0)
                  Text(
                    '$childCount sub-kategori',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade400,
                    ),
                  ),
              ],
            ),
          ),
          _DeleteButton(onTap: onDelete),
        ],
      ),
    );
  }
}

// ─── Child row ────────────────────────────────────────────────────
class _ChildRow extends StatelessWidget {
  final String name;
  final VoidCallback onDelete;
  final bool isLast;

  const _ChildRow({
    required this.name,
    required this.onDelete,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
          child: Row(
            children: [
              // Indent line
              Container(
                width: 1.5,
                height: 28,
                margin: const EdgeInsets.only(left: 13, right: 11),
                color: Colors.grey.shade200,
              ),
              Icon(
                Icons.folder_outlined,
                size: 14,
                color: Colors.grey.shade400,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
              _DeleteButton(onTap: onDelete),
            ],
          ),
        ),
        if (!isLast) Divider(height: 1, color: Colors.grey.shade100),
      ],
    );
  }
}

// ─── Delete button ────────────────────────────────────────────────
class _DeleteButton extends StatelessWidget {
  final VoidCallback onTap;

  const _DeleteButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(
          Icons.delete_outline_rounded,
          size: 17,
          color: Colors.grey.shade400,
        ),
      ),
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.folder_off_outlined, size: 44, color: Colors.grey.shade300),
          const SizedBox(height: 10),
          Text(
            'Belum ada kategori',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tambahkan kategori untuk mengorganisir produk',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded, size: 16),
            label: const Text('Tambah Kategori'),
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
          ),
        ],
      ),
    );
  }
}