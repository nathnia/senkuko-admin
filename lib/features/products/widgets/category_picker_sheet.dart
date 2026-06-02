import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:senkukoadmin/constant/app_colors.dart';
import 'package:senkukoadmin/constant/app_error_state.dart';
import 'package:senkukoadmin/constant/app_searchbar.dart';
import 'package:senkukoadmin/features/products/controllers/category_controller.dart';
import 'package:senkukoadmin/features/products/models/category_model.dart';
import 'package:senkukoadmin/routes/routes.dart';

class CategoryPickerSheet extends StatefulWidget {
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

  void _toggleGroup(String parentId) => setState(() {
    _collapsed.contains(parentId)
        ? _collapsed.remove(parentId)
        : _collapsed.add(parentId);
  });

  void _select(CategoryData cat) => Navigator.of(context).pop(cat);

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      controller: _sheetC,
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 1.0,
      snap: true,
      snapSizes: const [0.65, 1.0],
      expand: false,
      builder: (ctx, sc) =>
          _SheetShell(header: _buildHeader(), body: _buildBody(sc)),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background, // matches sheet background
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFCCCCCC),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 14),
          // Title row
          Stack(
            alignment: Alignment.center,
            children: [
              const Center(
                child: Text(
                  'Pilih Kategori',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                    color: Colors.black,
                  ),
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
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.settings_outlined,
                            size: 12,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Kelola',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          // Search bar — white on grey background pops nicely
          AppSearchBar(
            hintText: 'Cari kategori...',
            onChanged: _onSearchChanged,
            textController: _searchC,
          ),
        ],
      ),
    );
  }

  Widget _buildBody(ScrollController sc) {
    return Obx(() {
      if (_categoryC.isLoading.value) return const _LoadingState();
      if (_categoryC.hasError.value) {
        return AppErrorState(
          message: 'Gagal memuat daftar kategori',
          onRetry: _categoryC.fetchCategories,
        );
      }

      final parents = _categoryC.parentCategories;
      if (parents.isEmpty) {
        return const _EmptyState(
          icon: Icons.folder_off_outlined,
          message: 'Belum ada kategori',
        );
      }

      if (_searchQuery.isNotEmpty) return _buildSearchResults(sc);
      return _buildGroupedList(sc, parents);
    });
  }

  Widget _buildSearchResults(ScrollController sc) {
    final results = _categoryC.categoryList.where((c) {
      return c.name.toLowerCase().contains(_searchQuery) ||
          (c.parentName?.toLowerCase().contains(_searchQuery) ?? false);
    }).toList();

    if (results.isEmpty) {
      return const _EmptyState(
        icon: Icons.search_off_rounded,
        message: 'Kategori tidak ditemukan',
      );
    }

    // Search results: single white card, items separated by dividers
    return ListView(
      controller: sc,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      children: [
        _WhiteCard(
          children: results.map((cat) {
            final isSelectable = _categoryC.getSubCategories(cat.id).isEmpty;
            return _CategoryTile(
              label: cat.parentName != null
                  ? '${cat.parentName} › ${cat.name}'
                  : cat.name,
              isSelectable: isSelectable,
              hasParentLabel: cat.parentName != null,
              onTap: isSelectable ? () => _select(cat) : null,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildGroupedList(ScrollController sc, List<CategoryData> parents) {
    return ListView.separated(
      controller: sc,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      itemCount: parents.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final parent = parents[i];
        final children = _categoryC.getSubCategories(parent.id);
        final hasChildren = children.isNotEmpty;
        final isCollapsed = _collapsed.contains(parent.id);

        if (!hasChildren) {
          // Standalone — single-row white card
          return _WhiteCard(
            children: [
              _StandaloneRow(name: parent.name, onTap: () => _select(parent)),
            ],
          );
        }

        return _WhiteCard(
          children: [
            // Parent row (collapsible header)
            _ParentRow(
              name: parent.name,
              isCollapsed: isCollapsed,
              onTap: () => _toggleGroup(parent.id),
            ),
            // Children — animated show/hide
            AnimatedCrossFade(
              firstChild: Column(
                children: _withDividers(
                  children
                      .map(
                        (c) => _CategoryTile(
                          label: c.name,
                          isSelectable: true,
                          onTap: () => _select(c),
                        ),
                      )
                      .toList(),
                ),
              ),
              secondChild: const SizedBox.shrink(),
              crossFadeState: isCollapsed
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 200),
            ),
          ],
        );
      },
    );
  }

  List<Widget> _withDividers(List<Widget> items) {
    final r = <Widget>[];
    for (int i = 0; i < items.length; i++) {
      r.add(
        const Divider(
          height: 1,
          indent: 16,
          endIndent: 16,
          color: Color(0xFFF2F2F2),
        ),
      );
      r.add(items[i]);
    }
    return r;
  }
}

// ─── White Card container (no border, no shadow) ──────────────────────────────

class _WhiteCard extends StatelessWidget {
  final List<Widget> children;
  const _WhiteCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

// ─── Parent row (collapsible header inside card) ──────────────────────────────

class _ParentRow extends StatelessWidget {
  final String name;
  final bool isCollapsed;
  final VoidCallback onTap;
  const _ParentRow({
    required this.name,
    required this.isCollapsed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            AnimatedRotation(
              turns: isCollapsed ? -0.25 : 0,
              duration: const Duration(milliseconds: 200),
              child: const Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 18,
                color: AppColors.subtext,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.subtitle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Standalone row (no children) ────────────────────────────────────────────

class _StandaloneRow extends StatelessWidget {
  final String name;
  final VoidCallback onTap;
  const _StandaloneRow({required this.name, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Text(
                name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.subtitle,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: Color(0xFFCCCCCC),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Category Tile (child item) ───────────────────────────────────────────────

class _CategoryTile extends StatelessWidget {
  final String label;
  final bool isSelectable;
  final bool hasParentLabel;
  final VoidCallback? onTap;

  const _CategoryTile({
    required this.label,
    required this.isSelectable,
    this.hasParentLabel = false,
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
            const Icon(
              Icons.chevron_right_rounded,
              size: 16,
              color: Color(0xFFCCCCCC),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: isSelectable
                      ? AppColors.subtitle
                      : AppColors.subtext,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Sheet Shell ──────────────────────────────────────────────────────────────

class _SheetShell extends StatelessWidget {
  final Widget header;
  final Widget body;
  const _SheetShell({required this.header, required this.body});

  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(
      // Grey background — white cards "float" on it without any shadow/border
      color: AppColors.background,
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    child: Column(
      children: [
        header,
        Expanded(child: body),
      ],
    ),
  );
}

// ─── States ───────────────────────────────────────────────────────────────────

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2.5),
        const SizedBox(height: 12),
        const Text(
          'Memuat data...',
          style: TextStyle(fontSize: 13, color: AppColors.subtext),
        ),
      ],
    ),
  );
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: const BoxDecoration(
            color: AppColors.background,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 28, color: const Color(0xFFCCCCCC)),
        ),
        const SizedBox(height: 12),
        Text(
          message,
          style: const TextStyle(fontSize: 14, color: AppColors.subtext),
        ),
      ],
    ),
  );
}
