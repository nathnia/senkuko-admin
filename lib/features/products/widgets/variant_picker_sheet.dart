import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:senkukoadmin/constant/app_colors.dart';
import 'package:senkukoadmin/constant/app_error_state.dart';
import 'package:senkukoadmin/constant/app_searchbar.dart';
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

  void _select(VariantData v) => Navigator.of(context).pop(v);

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
      builder: (ctx, sc) => Container(
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildBody(sc)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFCCCCCC),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Pilih Varian',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
              color: Color(0xFF111111),
            ),
          ),
          const SizedBox(height: 12),
          AppSearchBar(
            hintText: 'Cari nama varian atau produk...',
            onChanged: _onSearchChanged,
            textController: _searchC,
          ),
        ],
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

    // Search: flat list, show product name as subtitle
    if (_searchQuery.isNotEmpty) {
      return ListView(
        controller: sc,
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
        children: [
          _WhiteCard(
            children: _withDividers(
              _filtered.map((v) => _VariantTile(
                variant: v,
                productName: _productNames[v.productId],
                onTap: () => _select(v),
              )).toList(),
            ),
          ),
        ],
      );
    }

    // Grouped by product — no collapse, plain text section label
    final grouped = <String, List<VariantData>>{};
    for (final v in _all) {
      grouped.putIfAbsent(v.productId, () => []).add(v);
    }
    final ids = grouped.keys.toList();

    return ListView.separated(
      controller: sc,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      itemCount: ids.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final pid = ids[i];
        final pname = _productNames[pid] ?? pid;
        final variants = grouped[pid]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 6),
              child: Text(
                pname,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.subtext,
                  letterSpacing: 0.2,
                ),
              ),
            ),
            _WhiteCard(
              children: _withDividers(
                variants.map((v) => _VariantTile(
                  variant: v,
                  onTap: () => _select(v),
                )).toList(),
              ),
            ),
          ],
        );
      },
    );
  }

  List<Widget> _withDividers(List<Widget> items) {
    final r = <Widget>[];
    for (int i = 0; i < items.length; i++) {
      if (i > 0) r.add(const Divider(height: 1, indent: 16, endIndent: 16, color: Color(0xFFF2F2F2)));
      r.add(items[i]);
    }
    return r;
  }
}

// ─── White Card ───────────────────────────────────────────────────────────────

class _WhiteCard extends StatelessWidget {
  final List<Widget> children;
  const _WhiteCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
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

// ─── Variant Tile ─────────────────────────────────────────────────────────────

class _VariantTile extends StatelessWidget {
  final VariantData variant;
  final String? productName;
  final VoidCallback onTap;

  const _VariantTile({
    required this.variant,
    required this.onTap,
    this.productName,
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    variant.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  if (productName != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      productName!,
                      style: TextStyle(fontSize: 12, color: AppColors.subtext),
                    ),
                  ],
                  if (variant.unitName != null) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        variant.unitName!,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.subtext,
                        ),
                      ),
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
        Text('Memuat data...', style: TextStyle(fontSize: 13, color: AppColors.subtext)),
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
          decoration: const BoxDecoration(color: Color(0xFFEAEAEA), shape: BoxShape.circle),
          child: Icon(icon, size: 28, color: const Color(0xFFCCCCCC)),
        ),
        const SizedBox(height: 12),
        Text(message, style: TextStyle(fontSize: 14, color: AppColors.subtext)),
      ],
    ),
  );
}