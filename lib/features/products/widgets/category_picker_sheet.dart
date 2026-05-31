import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:senkukoadmin/constant/app_error_state.dart';
import 'package:senkukoadmin/features/products/controllers/category_controller.dart';
import 'package:senkukoadmin/features/products/models/category_model.dart';
import 'package:senkukoadmin/routes/routes.dart';

class CategoryPickerSheet extends StatefulWidget {
  /// Set [showManageLink] to true to show the "Kelola" shortcut in the header.
  final bool showManageLink;

  const CategoryPickerSheet({super.key, this.showManageLink = false});

  static Future<CategoryData?> show(
    BuildContext context, {
    bool showManageLink = false,
  }) {
    return showModalBottomSheet<CategoryData>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (_) => CategoryPickerSheet(showManageLink: showManageLink),
    );
  }

  @override
  State<CategoryPickerSheet> createState() => _CategoryPickerSheetState();
}

class _CategoryPickerSheetState extends State<CategoryPickerSheet> {
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

  CategoryController get _categoryC => Get.find<CategoryController>();

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

  void _select(CategoryData category) => Navigator.of(context).pop(category);

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
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildBody(scrollController)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
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
          Stack(
            alignment: Alignment.center,
            children: [
              const Center(
                child: Text(
                  'Pilih Kategori',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
              ),
              if (widget.showManageLink)
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
                        Icon(Icons.settings_outlined,
                            size: 13, color: Colors.grey.shade400),
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
          TextField(
            controller: _searchC,
            onChanged: _onSearchChanged,
            onTap: _expandSheet,
            decoration: InputDecoration(
              hintText: 'Cari kategori...',
              hintStyle:
                  TextStyle(fontSize: 13, color: Colors.grey.shade400),
              prefixIcon:
                  Icon(Icons.search_rounded, color: Colors.grey.shade400, size: 18),
              suffixIcon: _searchQuery.isNotEmpty
                  ? GestureDetector(
                      onTap: () {
                        _searchC.clear();
                        _onSearchChanged('');
                      },
                      child: Icon(Icons.close_rounded,
                          color: Colors.grey.shade400, size: 16),
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
      if (_categoryC.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      if (_categoryC.hasError.value) {
        return AppErrorState(
          message: 'Gagal memuat daftar kategori',
          onRetry: _categoryC.fetchCategories,
        );
      }

      final parents = _categoryC.parentCategories;
      if (parents.isEmpty) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.folder_off_outlined,
                  size: 40, color: Colors.grey.shade300),
              const SizedBox(height: 8),
              Text(
                'Belum ada kategori',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
              ),
            ],
          ),
        );
      }

      if (_searchQuery.isNotEmpty) {
        return _buildSearchResults(scrollController);
      }

      return _buildGroupedList(scrollController, parents);
    });
  }

  Widget _buildSearchResults(ScrollController scrollController) {
    final results = _categoryC.categoryList.where((c) {
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
        final isSelectable = _categoryC.getSubCategories(cat.id).isEmpty;
        return _CategoryTile(
          label: cat.parentName != null
              ? '${cat.parentName} › ${cat.name}'
              : cat.name,
          isSelectable: isSelectable,
          onTap: isSelectable ? () => _select(cat) : null,
        );
      },
    );
  }

  Widget _buildGroupedList(
      ScrollController scrollController, List<CategoryData> parents) {
    return ListView.builder(
      controller: scrollController,
      itemCount: parents.length,
      itemBuilder: (_, i) {
        final parent = parents[i];
        final children = _categoryC.getSubCategories(parent.id);
        final hasChildren = children.isNotEmpty;
        final isCollapsed = _collapsed.contains(parent.id);

        return _CategoryGroup(
          parentName: parent.name,
          parentId: parent.id,
          hasChildren: hasChildren,
          isCollapsed: isCollapsed,
          parentSelectable: !hasChildren,
          onToggle: hasChildren ? () => _toggleGroup(parent.id) : null,
          onTapParent: !hasChildren ? () => _select(parent) : null,
          children: children
              .map(
                (c) => _CategoryTile(
                  label: c.name,
                  isSelectable: true,
                  onTap: () => _select(c),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// CATEGORY GROUP — matches _CategorySelectorSheet style exactly
// ═══════════════════════════════════════════════════════════════

class _CategoryGroup extends StatelessWidget {
  final String parentName;
  final String parentId;
  final bool hasChildren;
  final bool isCollapsed;
  final bool parentSelectable;
  final VoidCallback? onToggle;
  final VoidCallback? onTapParent;
  final List<Widget> children;

  const _CategoryGroup({
    required this.parentName,
    required this.parentId,
    required this.hasChildren,
    required this.isCollapsed,
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
                      color: Colors.grey.shade500,
                    ),
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
// CATEGORY TILE
// ═══════════════════════════════════════════════════════════════

class _CategoryTile extends StatelessWidget {
  final String label;
  final bool isSelectable;
  final VoidCallback? onTap;

  const _CategoryTile({
    required this.label,
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
                      : Colors.black87,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                size: 18, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}