// FILE: lib/features/products/widgets/product_info_form.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:senkukoadmin/constant/app_colors.dart';
import 'package:senkukoadmin/constant/app_error_state.dart';
import 'package:senkukoadmin/constant/app_textfield.dart';
import 'package:senkukoadmin/features/products/controllers/category_controller.dart';
import 'package:senkukoadmin/features/products/controllers/product_controller.dart';
import 'package:senkukoadmin/features/products/widgets/app_card.dart';
import 'package:senkukoadmin/routes/routes.dart';

class ProductInfoForm extends StatelessWidget {
  final ProductController controller;
  const ProductInfoForm({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
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
          _CategorySelector(controller: controller),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// CATEGORY SELECTOR — trigger button only, no state
// ═══════════════════════════════════════════════════════════════
class _CategorySelector extends StatelessWidget {
  final ProductController controller;
  const _CategorySelector({required this.controller});

  CategoryController get _categoryC => Get.find<CategoryController>();

  @override
  Widget build(BuildContext context) {
    return Column(
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
        Obx(() {
          final selected = _categoryC.categoryList.firstWhereOrNull(
            (c) => c.id == controller.selectedCategoryId.value,
          );
          final displayName = selected == null
              ? 'Pilih Kategori'
              : selected.parentName != null
              ? '${selected.parentName} › ${selected.name}'
              : selected.name;

          return GestureDetector(
            onTap: () => _openSheet(context),
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
        }),
      ],
    );
  }

  void _openSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (_) => _CategorySelectorSheet(
        categoryC: _categoryC,
        selectedId: controller.selectedCategoryId.value,
        onSelected: (id) {
          controller.selectedCategoryId.value = id;
          controller.checkDirty();
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// CATEGORY SELECTOR SHEET
// StatefulWidget — owns all ephemeral UI state.
// ═══════════════════════════════════════════════════════════════
class _CategorySelectorSheet extends StatefulWidget {
  final CategoryController categoryC;
  final String selectedId;
  final void Function(String id) onSelected;

  const _CategorySelectorSheet({
    required this.categoryC,
    required this.selectedId,
    required this.onSelected,
  });

  @override
  State<_CategorySelectorSheet> createState() => _CategorySelectorSheetState();
}

class _CategorySelectorSheetState extends State<_CategorySelectorSheet> {
  late final DraggableScrollableController _sheetC;
  late final TextEditingController _searchC;
  String _searchQuery = '';
  final Set<String> _collapsed = {};

  @override
  void initState() {
    super.initState();
    _sheetC = DraggableScrollableController();
    _searchC = TextEditingController();
  }

  @override
  void dispose() {
    _sheetC.dispose();
    _searchC.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value.toLowerCase().trim();
      if (_searchQuery.isNotEmpty) _collapsed.clear();
    });
  }

  void _toggleGroup(String parentId) {
    setState(() {
      _collapsed.contains(parentId)
          ? _collapsed.remove(parentId)
          : _collapsed.add(parentId);
    });
  }

  void _select(String id) {
    widget.onSelected(id);
    Get.back();
  }

  void _expandSheet() {
    if (_sheetC.isAttached && _sheetC.size < 1.0) {
      _sheetC.animateTo(
        1.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      controller: _sheetC,
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 1.0,
      snap: true,
      snapSizes: const [0.6, 1.0],
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(child: _buildBody(scrollController)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Title centered + kelola link on right
          Stack(
            alignment: Alignment.center,
            children: [
              const Center(
                child: Text(
                  'Pilih Kategori',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
              ),
              Positioned(
                right: 0,
                child: GestureDetector(
                  onTap: () {
                    Get.back();
                    Get.toNamed(AppRoutes.manageCategories);
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.settings_outlined,
                        size: 13,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Kelola',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade400,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Search bar
          TextField(
            controller: _searchC,
            onChanged: _onSearchChanged,
            onTap: _expandSheet,
            decoration: InputDecoration(
              hintText: 'Cari kategori...',
              hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
              prefixIcon: Icon(
                Icons.search_rounded,
                color: Colors.grey.shade400,
                size: 18,
              ),
              suffixIcon: _searchQuery.isNotEmpty
                  ? GestureDetector(
                      onTap: () {
                        _searchC.clear();
                        _onSearchChanged('');
                      },
                      child: Icon(
                        Icons.close_rounded,
                        color: Colors.grey.shade400,
                        size: 16,
                      ),
                    )
                  : null,
              filled: true,
              fillColor: Colors.grey.shade100,
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              isDense: true,
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildBody(ScrollController scrollController) {
    return Obx(() {
      if (widget.categoryC.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      if (widget.categoryC.hasError.value) {
        return AppErrorState(
          message: 'Gagal memuat kategori',
          onRetry: widget.categoryC.fetchCategories,
        );
      }

      final parents = widget.categoryC.parentCategories;
      if (parents.isEmpty) return _buildEmptyState();
      if (_searchQuery.isNotEmpty) return _buildSearchResults(scrollController);
      return _buildGroupedList(scrollController, parents);
    });
  }

  Widget _buildSearchResults(ScrollController scrollController) {
    final results = widget.categoryC.categoryList.where((c) {
      return c.name.toLowerCase().contains(_searchQuery) ||
          (c.parentName?.toLowerCase().contains(_searchQuery) ?? false);
    }).toList();

    if (results.isEmpty) {
      return Center(
        child: Text(
          'Kategori tidak ditemukan',
          style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
        ),
      );
    }

    return ListView.builder(
      controller: scrollController,
      itemCount: results.length,
      itemBuilder: (_, i) {
        final cat = results[i];
        final isSelectable = widget.categoryC.getSubCategories(cat.id).isEmpty;
        return _SelectableTile(
          label: cat.parentName != null
              ? '${cat.parentName} › ${cat.name}'
              : cat.name,
          isSelected: widget.selectedId == cat.id,
          isSelectable: isSelectable,
          onTap: isSelectable ? () => _select(cat.id) : null,
        );
      },
    );
  }

  Widget _buildGroupedList(ScrollController scrollController, List parents) {
    return ListView.builder(
      controller: scrollController,
      itemCount: parents.length,
      itemBuilder: (_, i) {
        final parent = parents[i];
        final children = widget.categoryC.getSubCategories(parent.id);
        final hasChildren = children.isNotEmpty;
        final isCollapsed = _collapsed.contains(parent.id);

        return _CategoryGroup(
          parentName: parent.name,
          parentId: parent.id,
          hasChildren: hasChildren,
          isCollapsed: isCollapsed,
          parentSelected: widget.selectedId == parent.id,
          parentSelectable: !hasChildren,
          onToggle: hasChildren ? () => _toggleGroup(parent.id) : null,
          onTapParent: !hasChildren ? () => _select(parent.id) : null,
          children: children
              .map(
                (c) => _SelectableTile(
                  label: c.name,
                  isSelected: widget.selectedId == c.id,
                  isSelectable: true,
                  onTap: () => _select(c.id),
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.folder_off_outlined,
            size: 40,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 8),
          Text(
            'Belum ada kategori',
            style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () {
              Get.back();
              Get.toNamed(AppRoutes.manageCategories);
            },
            icon: const Icon(Icons.settings_outlined, size: 14),
            label: const Text('Kelola Kategori'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              textStyle: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// CATEGORY GROUP — subtle header + collapsible children
// ═══════════════════════════════════════════════════════════════
class _CategoryGroup extends StatelessWidget {
  final String parentName;
  final String parentId;
  final bool hasChildren;
  final bool isCollapsed;
  final bool parentSelected;
  final bool parentSelectable;
  final VoidCallback? onToggle;
  final VoidCallback? onTapParent;
  final List<Widget> children;

  const _CategoryGroup({
    required this.parentName,
    required this.parentId,
    required this.hasChildren,
    required this.isCollapsed,
    required this.parentSelected,
    required this.parentSelectable,
    required this.onToggle,
    required this.onTapParent,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: parentSelectable ? onTapParent : onToggle,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    parentName,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: parentSelected
                          ? AppColors.primary
                          : Colors.grey.shade500,
                    ),
                  ),
                ),
                if (parentSelected)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Icon(
                      Icons.check_rounded,
                      color: AppColors.primary,
                      size: 13,
                    ),
                  ),
                if (hasChildren)
                  AnimatedRotation(
                    turns: isCollapsed ? -0.25 : 0,
                    duration: const Duration(milliseconds: 180),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 16,
                      color: Colors.grey.shade400,
                    ),
                  ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: Column(children: children),
          secondChild: const SizedBox.shrink(),
          crossFadeState: isCollapsed
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 180),
        ),
        Divider(height: 1, color: Colors.grey.shade100),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// SELECTABLE TILE
// ═══════════════════════════════════════════════════════════════
class _SelectableTile extends StatelessWidget {
  final String label;
  final bool isSelected;
  final bool isSelectable;
  final VoidCallback? onTap;

  const _SelectableTile({
    required this.label,
    required this.isSelected,
    required this.isSelectable,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: !isSelectable
                      ? Colors.grey.shade400
                      : isSelected
                      ? AppColors.primary
                      : Colors.black87,
                  fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                ),
              ),
            ),
            if (isSelected)
              Icon(Icons.check_rounded, color: AppColors.primary, size: 16),
          ],
        ),
      ),
    );
  }
}