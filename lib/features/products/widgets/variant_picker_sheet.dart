import 'package:flutter/material.dart';
import 'package:get/get.dart';
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

  // productId → productName, built once after load
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
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final variantC = Get.find<ProductVariantController>();

      // Reuse cached list if available
      if (variantC.allVariants.isEmpty) {
        await variantC.fetchAllVariants();
      }

      if (!mounted) return;

      // Build productId → name map from ProductController
      if (Get.isRegistered<ProductController>()) {
        final products = Get.find<ProductController>().productList;
        _productNames = {for (final p in products) p.id: p.name};
      }

      final list = variantC.allVariants.toList();
      setState(() {
        _all = list;
        _filtered = list;
      });
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
              final productName =
                  (_productNames[v.productId] ?? '').toLowerCase();
              return v.name.toLowerCase().contains(_searchQuery) ||
                  productName.contains(_searchQuery);
            }).toList();
    });
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

  void _select(VariantData variant) => Navigator.of(context).pop(variant);

  void _toggleGroup(String productId) {
    setState(() {
      _collapsed.contains(productId)
          ? _collapsed.remove(productId)
          : _collapsed.add(productId);
    });
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

  // ── Header ──────────────────────────────────────────────────────────────

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
          const Center(
            child: Text(
              'Pilih Variant',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _searchC,
            onChanged: _onSearchChanged,
            onTap: _expandSheet,
            decoration: InputDecoration(
              hintText: 'Cari nama variant atau produk...',
              hintStyle:
                  TextStyle(fontSize: 13, color: Colors.grey.shade400),
              prefixIcon: Icon(Icons.search_rounded,
                  color: Colors.grey.shade400, size: 18),
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

  // ── Body ────────────────────────────────────────────────────────────────

  Widget _buildBody(ScrollController scrollController) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_hasError) {
      return AppErrorState(
        message: 'Gagal memuat daftar variant',
        onRetry: _load,
      );
    }

    if (_filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inventory_2_outlined,
                size: 40, color: Colors.grey.shade300),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Variant tidak ditemukan'
                  : 'Belum ada variant',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
            ),
          ],
        ),
      );
    }

    // Flat list when searching
    if (_searchQuery.isNotEmpty) {
      return _buildFlatList(scrollController, _filtered);
    }

    // Grouped by product when not searching
    return _buildGroupedList(scrollController);
  }

  Widget _buildFlatList(
      ScrollController scrollController, List<VariantData> variants) {
    return ListView.builder(
      controller: scrollController,
      itemCount: variants.length,
      itemBuilder: (_, i) {
        final v = variants[i];
        return _VariantTile(
          variant: v,
          productName: _productNames[v.productId],
          showProductName: true,
          onTap: () => _select(v),
        );
      },
    );
  }

  Widget _buildGroupedList(ScrollController scrollController) {
    // Group variants by productId, preserving insertion order
    final grouped = <String, List<VariantData>>{};
    for (final v in _all) {
      grouped.putIfAbsent(v.productId, () => []).add(v);
    }

    final productIds = grouped.keys.toList();

    return ListView.builder(
      controller: scrollController,
      itemCount: productIds.length,
      itemBuilder: (_, i) {
        final productId = productIds[i];
        final productName = _productNames[productId] ?? productId;
        final variants = grouped[productId]!;
        final isCollapsed = _collapsed.contains(productId);

        return _VariantGroup(
          productName: productName,
          productId: productId,
          isCollapsed: isCollapsed,
          onToggle: () => _toggleGroup(productId),
          children: variants
              .map(
                (v) => _VariantTile(
                  variant: v,
                  onTap: () => _select(v),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// VARIANT GROUP — collapsible product header
// ═══════════════════════════════════════════════════════════════

class _VariantGroup extends StatelessWidget {
  final String productName;
  final String productId;
  final bool isCollapsed;
  final VoidCallback onToggle;
  final List<Widget> children;

  const _VariantGroup({
    required this.productName,
    required this.productId,
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
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    productName,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ),
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
// VARIANT TILE
// ═══════════════════════════════════════════════════════════════

class _VariantTile extends StatelessWidget {
  final VariantData variant;
  final String? productName;
  final bool showProductName;
  final VoidCallback onTap;

  const _VariantTile({
    required this.variant,
    required this.onTap,
    this.productName,
    this.showProductName = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    variant.name,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                  if (showProductName && productName != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      productName!,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                  if (variant.unitName != null) ...[
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(4),
                        border:
                            Border.all(color: Colors.grey.shade300, width: 0.5),
                      ),
                      child: Text(
                        variant.unitName!,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ],
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