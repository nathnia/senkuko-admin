import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:senkukoadmin/constant/app_colors.dart';
import 'package:senkukoadmin/constant/app_error_state.dart';
import 'package:senkukoadmin/features/products/controllers/product_controller.dart';
import 'package:senkukoadmin/features/products/controllers/product_variant_controller.dart';
import 'package:senkukoadmin/features/products/models/product_variant_model.dart';

class VariantPickerSheet extends StatefulWidget {
  const VariantPickerSheet({super.key});

  static Future<VariantData?> show(BuildContext context) {
    return showModalBottomSheet<VariantData>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (_) => const VariantPickerSheet(),
    );
  }

  @override
  State<VariantPickerSheet> createState() => _VariantPickerSheetState();
}

class _VariantPickerSheetState extends State<VariantPickerSheet> {
  late final DraggableScrollableController _sheetC;
  late final TextEditingController _searchC;

  List<VariantData> _all = [];
  List<VariantData> _filtered = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _searchQuery = '';
  Map<String, String> _productNames = {};
  final Set<String> _collapsed = {};

  @override
  void initState() {
    super.initState();
    _sheetC = DraggableScrollableController();
    _searchC = TextEditingController();
    _load();
  }

  @override
  void dispose() {
    _sheetC.dispose();
    _searchC.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() { _isLoading = true; _hasError = false; });
    try {
      final variantC = Get.find<ProductVariantController>();
      if (variantC.allVariants.isEmpty) await variantC.fetchAllVariants();
      if (!mounted) return;
      if (Get.isRegistered<ProductController>()) {
        final products = Get.find<ProductController>().productList;
        _productNames = {for (final p in products) p.id: p.name};
      }
      final list = variantC.allVariants.toList();
      setState(() { _all = list; _filtered = list; });
    } catch (_) {
      if (mounted) setState(() => _hasError = true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value.toLowerCase().trim();
      _filtered = _searchQuery.isEmpty
          ? _all
          : _all.where((v) {
              final pn = (_productNames[v.productId] ?? '').toLowerCase();
              return v.name.toLowerCase().contains(_searchQuery) || pn.contains(_searchQuery);
            }).toList();
    });
  }

  void _expandSheet() {
    if (_sheetC.isAttached && _sheetC.size < 1.0) {
      _sheetC.animateTo(1.0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  void _select(VariantData v) => Navigator.of(context).pop(v);

  void _toggleGroup(String productId) => setState(() {
    _collapsed.contains(productId) ? _collapsed.remove(productId) : _collapsed.add(productId);
  });

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
        header: _PickerHeader(
          title: 'Pilih Varian',
          searchHint: 'Cari nama varian atau produk...',
          searchController: _searchC,
          searchQuery: _searchQuery,
          onSearchChanged: _onSearchChanged,
          onSearchTap: _expandSheet,
          onClearSearch: () { _searchC.clear(); _onSearchChanged(''); },
        ),
        body: _buildBody(sc),
      ),
    );
  }

  Widget _buildBody(ScrollController sc) {
    if (_isLoading) return const _LoadingState();
    if (_hasError) return AppErrorState(message: 'Gagal memuat daftar varian', onRetry: _load);
    if (_filtered.isEmpty) {
      return _EmptyState(
      icon: Icons.inventory_2_outlined,
      message: _searchQuery.isNotEmpty ? 'Varian tidak ditemukan' : 'Belum ada varian',
    );
    }
    if (_searchQuery.isNotEmpty) {
      return ListView.builder(
        controller: sc,
        padding: const EdgeInsets.only(bottom: 20),
        itemCount: _filtered.length,
        itemBuilder: (_, i) {
          final v = _filtered[i];
          return _VariantTile(variant: v, productName: _productNames[v.productId], showProductName: true, onTap: () => _select(v));
        },
      );
    }
    final grouped = <String, List<VariantData>>{};
    for (final v in _all) {
      grouped.putIfAbsent(v.productId, () => []).add(v);
    }
    final ids = grouped.keys.toList();
    return ListView.builder(
      controller: sc,
      padding: const EdgeInsets.only(bottom: 20),
      itemCount: ids.length,
      itemBuilder: (_, i) {
        final pid = ids[i];
        final pname = _productNames[pid] ?? pid;
        final variants = grouped[pid]!;
        final isCollapsed = _collapsed.contains(pid);
        return _GroupSection(
          label: pname,
          count: variants.length,
          isCollapsed: isCollapsed,
          onToggle: () => _toggleGroup(pid),
          children: variants.map((v) => _VariantTile(variant: v, onTap: () => _select(v))).toList(),
        );
      },
    );
  }
}

// ─── Shared Widgets ───────────────────────────────────────────────────────────

class _SheetShell extends StatelessWidget {
  final Widget header;
  final Widget body;
  const _SheetShell({required this.header, required this.body});
  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(
      color: Color(0xFFF6F6F6),
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    child: Column(children: [header, Expanded(child: body)]),
  );
}

class _PickerHeader extends StatelessWidget {
  final String title;
  final String searchHint;
  final TextEditingController searchController;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onSearchTap;
  final VoidCallback onClearSearch;

  const _PickerHeader({
    required this.title,
    required this.searchHint,
    required this.searchController,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.onSearchTap,
    required this.onClearSearch,
  });

  @override
  Widget build(BuildContext context) {
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
          Center(child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: -0.2))),
          const SizedBox(height: 14),
          Container(
            height: 44,
            decoration: BoxDecoration(color: const Color(0xFFF2F2F2), borderRadius: BorderRadius.circular(12)),
            child: TextField(
              controller: searchController,
              onChanged: onSearchChanged,
              onTap: onSearchTap,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: searchHint,
                hintStyle: const TextStyle(fontSize: 14, color: Color(0xFFBBBBBB)),
                prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFFBBBBBB), size: 20),
                suffixIcon: searchQuery.isNotEmpty
                    ? GestureDetector(
                        onTap: onClearSearch,
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
}

class _GroupSection extends StatelessWidget {
  final String label;
  final int count;
  final bool isCollapsed;
  final VoidCallback onToggle;
  final List<Widget> children;

  const _GroupSection({
    required this.label,
    required this.count,
    required this.isCollapsed,
    required this.onToggle,
    required this.children,
  });

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
              child: Column(children: _buildDivided(children)),
            ),
          ),
          secondChild: const SizedBox.shrink(),
          crossFadeState: isCollapsed ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
        ),
      ],
    );
  }

  List<Widget> _buildDivided(List<Widget> items) {
    final result = <Widget>[];
    for (int i = 0; i < items.length; i++) {
      result.add(items[i]);
      if (i < items.length - 1) result.add(const Divider(height: 1, indent: 16, endIndent: 16, color: Color(0xFFF5F5F5)));
    }
    return result;
  }
}

class _VariantTile extends StatelessWidget {
  final VariantData variant;
  final String? productName;
  final bool showProductName;
  final VoidCallback onTap;

  const _VariantTile({required this.variant, required this.onTap, this.productName, this.showProductName = false});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(color: AppColors.primary.withAlpha(12), borderRadius: BorderRadius.circular(10)),
              child: Icon(Icons.layers_outlined, size: 16, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(variant.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A))),
                  if (showProductName && productName != null) ...[
                    const SizedBox(height: 2),
                    Text(productName!, style: const TextStyle(fontSize: 12, color: Color(0xFF999999))),
                  ],
                  if (variant.unitName != null) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(color: const Color(0xFFF2F2F2), borderRadius: BorderRadius.circular(6), border: Border.all(color: const Color(0xFFE8E8E8))),
                      child: Text(variant.unitName!, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF666666))),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFFCCCCCC)),
          ],
        ),
      ),
    );
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