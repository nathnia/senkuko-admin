import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:senkukoadmin/constant/app_colors.dart';
import 'package:senkukoadmin/constant/app_error_state.dart';
import 'package:senkukoadmin/features/products/controllers/category_controller.dart';
import 'package:senkukoadmin/features/products/models/category_model.dart';
import 'package:senkukoadmin/routes/routes.dart';

class CategoryPickerSheet extends StatefulWidget {
  final bool showManageLink;
  const CategoryPickerSheet({super.key, this.showManageLink = false});

  static Future<CategoryData?> show(BuildContext context, {bool showManageLink = false}) {
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
    _collapsed.contains(parentId) ? _collapsed.remove(parentId) : _collapsed.add(parentId);
  });

  void _select(CategoryData cat) => Navigator.of(context).pop(cat);

  void _expandSheet() {
    if (_sheetC.isAttached && _sheetC.size < 1.0) {
      _sheetC.animateTo(1.0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

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
      builder: (ctx, sc) => _SheetShell(
        header: _buildHeader(),
        body: _buildBody(sc),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [BoxShadow(color: Color(0x0A000000), blurRadius: 12, offset: Offset(0, 3))],
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(color: const Color(0xFFDDDDDD), borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 16),
          Stack(
            alignment: Alignment.center,
            children: [
              const Center(child: Text('Pilih Kategori', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: -0.2))),
              if (widget.showManageLink)
                Positioned(
                  right: 0,
                  child: GestureDetector(
                    onTap: () { Get.back(); Get.toNamed(AppRoutes.manageCategories); },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.settings_outlined, size: 12, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Text('Kelola', style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600)),
                      ]),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            height: 44,
            decoration: BoxDecoration(color: const Color(0xFFF2F2F2), borderRadius: BorderRadius.circular(12)),
            child: TextField(
              controller: _searchC,
              onChanged: _onSearchChanged,
              onTap: _expandSheet,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Cari kategori...',
                hintStyle: const TextStyle(fontSize: 14, color: Color(0xFFBBBBBB)),
                prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFFBBBBBB), size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? GestureDetector(
                        onTap: () { _searchC.clear(); _onSearchChanged(''); },
                        child: const Icon(Icons.cancel_rounded, color: Color(0xFFBBBBBB), size: 18),
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(ScrollController sc) {
    return Obx(() {
      if (_categoryC.isLoading.value) return const _LoadingState();
      if (_categoryC.hasError.value) return AppErrorState(message: 'Gagal memuat daftar kategori', onRetry: _categoryC.fetchCategories);

      final parents = _categoryC.parentCategories;
      if (parents.isEmpty) return const _EmptyState(icon: Icons.folder_off_outlined, message: 'Belum ada kategori');

      if (_searchQuery.isNotEmpty) return _buildSearchResults(sc);
      return _buildGroupedList(sc, parents);
    });
  }

  Widget _buildSearchResults(ScrollController sc) {
    final results = _categoryC.categoryList.where((c) {
      return c.name.toLowerCase().contains(_searchQuery) ||
          (c.parentName?.toLowerCase().contains(_searchQuery) ?? false);
    }).toList();

    if (results.isEmpty) return const _EmptyState(icon: Icons.search_off_rounded, message: 'Kategori tidak ditemukan');

    return ListView.builder(
      controller: sc,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
      itemCount: results.length,
      itemBuilder: (_, i) {
        final cat = results[i];
        final isSelectable = _categoryC.getSubCategories(cat.id).isEmpty;
        return _CategoryTile(
          label: cat.parentName != null ? '${cat.parentName} › ${cat.name}' : cat.name,
          isSelectable: isSelectable,
          hasParentLabel: cat.parentName != null,
          onTap: isSelectable ? () => _select(cat) : null,
        );
      },
    );
  }

  Widget _buildGroupedList(ScrollController sc, List<CategoryData> parents) {
    return ListView.builder(
      controller: sc,
      padding: const EdgeInsets.only(bottom: 20),
      itemCount: parents.length,
      itemBuilder: (_, i) {
        final parent = parents[i];
        final children = _categoryC.getSubCategories(parent.id);
        final hasChildren = children.isNotEmpty;
        final isCollapsed = _collapsed.contains(parent.id);

        if (!hasChildren) {
          // Standalone category — no children
          return _StandaloneCategory(
            name: parent.name,
            onTap: () => _select(parent),
          );
        }

        return _GroupSection(
          label: parent.name,
          count: children.length,
          isCollapsed: isCollapsed,
          onToggle: () => _toggleGroup(parent.id),
          children: children.map((c) => _CategoryTile(
            label: c.name,
            isSelectable: true,
            onTap: () => _select(c),
          )).toList(),
        );
      },
    );
  }
}

// ─── Category-specific tiles ──────────────────────────────────────────────────

class _StandaloneCategory extends StatelessWidget {
  final String name;
  final VoidCallback onTap;
  const _StandaloneCategory({required this.name, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 6, 12, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [BoxShadow(color: Color(0x06000000), blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          child: Row(
            children: [
              Container(
                width: 34, height: 34,
                decoration: BoxDecoration(color: AppColors.primary.withAlpha(12), borderRadius: BorderRadius.circular(10)),
                child: Icon(Icons.folder_outlined, size: 16, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A)))),
              const Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFFCCCCCC)),
            ],
          ),
        ),
      ),
    );
  }
}

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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 6, height: 6,
              decoration: BoxDecoration(
                color: isSelectable ? AppColors.primary.withAlpha(120) : const Color(0xFFDDDDDD),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isSelectable ? const Color(0xFF1A1A1A) : const Color(0xFFBBBBBB),
                ),
              ),
            ),
            if (isSelectable)
              const Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFFCCCCCC)),
          ],
        ),
      ),
    );
  }
}

// ─── Shared widgets (duplicated for standalone file) ─────────────────────────

class _SheetShell extends StatelessWidget {
  final Widget header;
  final Widget body;
  const _SheetShell({required this.header, required this.body});
  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(color: Color(0xFFF6F6F6), borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    child: Column(children: [header, Expanded(child: body)]),
  );
}

class _GroupSection extends StatelessWidget {
  final String label;
  final int count;
  final bool isCollapsed;
  final VoidCallback onToggle;
  final List<Widget> children;

  const _GroupSection({required this.label, required this.count, required this.isCollapsed, required this.onToggle, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: onToggle,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: Row(children: [
                    Text(label.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF999999), letterSpacing: 0.8)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                      decoration: BoxDecoration(color: AppColors.primary.withAlpha(15), borderRadius: BorderRadius.circular(20)),
                      child: Text('$count', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.primary)),
                    ),
                  ]),
                ),
                AnimatedRotation(
                  turns: isCollapsed ? -0.25 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Color(0xFFBBBBBB)),
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: const [BoxShadow(color: Color(0x06000000), blurRadius: 8, offset: Offset(0, 2))],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Column(children: _withDividers(children)),
            ),
          ),
          secondChild: const SizedBox.shrink(),
          crossFadeState: isCollapsed ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
        ),
      ],
    );
  }

  List<Widget> _withDividers(List<Widget> items) {
    final r = <Widget>[];
    for (int i = 0; i < items.length; i++) {
      r.add(items[i]);
      if (i < items.length - 1) r.add(const Divider(height: 1, indent: 34, endIndent: 16, color: Color(0xFFF5F5F5)));
    }
    return r;
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();
  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2.5),
      const SizedBox(height: 12),
      const Text('Memuat data...', style: TextStyle(fontSize: 13, color: Color(0xFFAAAAAA))),
    ]),
  );
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyState({required this.icon, required this.message});
  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 72, height: 72,
        decoration: const BoxDecoration(color: Color(0xFFF2F2F2), shape: BoxShape.circle),
        child: Icon(icon, size: 32, color: const Color(0xFFCCCCCC)),
      ),
      const SizedBox(height: 12),
      Text(message, style: const TextStyle(fontSize: 14, color: Color(0xFFAAAAAA))),
    ]),
  );
}