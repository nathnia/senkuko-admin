// ignore_for_file: unrelated_type_equality_checks

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:senkukoadmin/constant/app_colors.dart';
import 'package:senkukoadmin/constant/app_error_state.dart';
import 'package:senkukoadmin/features/products/controllers/product_controller.dart';
import 'package:senkukoadmin/features/products/models/product_model.dart';

class ProductPickerSheet extends StatefulWidget {
  const ProductPickerSheet({super.key});

  static Future<ProductData?> show(BuildContext context) {
    return showModalBottomSheet<ProductData>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (_) => const ProductPickerSheet(),
    );
  }

  @override
  State<ProductPickerSheet> createState() => _ProductPickerSheetState();
}

class _ProductPickerSheetState extends State<ProductPickerSheet> {
  late final DraggableScrollableController _sheetC;
  late final TextEditingController _searchC;

  List<ProductData> _all = [];
  List<ProductData> _filtered = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _searchQuery = '';

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

    if (Get.isRegistered<ProductController>()) {
      final list = Get.find<ProductController>().productList;
      if (list.isNotEmpty) {
        setState(() { _all = list.toList(); _filtered = _all; _isLoading = false; });
        return;
      }
    }

    try {
      final ctrl = Get.find<ProductController>();
      await ctrl.fetchProducts();
      if (!mounted) return;
      if (ctrl.hasError.value) {
        setState(() => _hasError = true);
      } else {
        final list = ctrl.productList;
        setState(() { _all = list.toList(); _filtered = _all; });
      }
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
          : _all.where((p) =>
              p.name.toLowerCase().contains(_searchQuery) ||
              p.skuCode.toLowerCase().contains(_searchQuery)).toList();
    });
  }

  void _expandSheet() {
    if (_sheetC.isAttached && _sheetC.size < 1.0) {
      _sheetC.animateTo(1.0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  void _select(ProductData product) => Navigator.of(context).pop(product);

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
          color: Color(0xFFF6F6F6),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(children: [
          _buildHeader(),
          Expanded(child: _buildBody(sc)),
        ]),
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
          const Text('Pilih Produk', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: -0.2)),
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
                hintText: 'Cari nama atau SKU...',
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
    if (_isLoading) {
      return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2.5),
        const SizedBox(height: 12),
        const Text('Memuat produk...', style: TextStyle(fontSize: 13, color: Color(0xFFAAAAAA))),
      ]),
    );
    }

    if (_hasError) return AppErrorState(message: 'Gagal memuat daftar produk', onRetry: _load);

    if (_filtered.isEmpty) {
      return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 72, height: 72,
          decoration: const BoxDecoration(color: Color(0xFFF2F2F2), shape: BoxShape.circle),
          child: const Icon(Icons.inventory_2_outlined, size: 32, color: Color(0xFFCCCCCC)),
        ),
        const SizedBox(height: 12),
        Text(
          _searchQuery.isNotEmpty ? 'Produk tidak ditemukan' : 'Belum ada produk',
          style: const TextStyle(fontSize: 14, color: Color(0xFFAAAAAA)),
        ),
      ]),
    );
    }

    return ListView.builder(
      controller: sc,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
      itemCount: _filtered.length,
      itemBuilder: (_, i) => _ProductCard(
        product: _filtered[i],
        onTap: () => _select(_filtered[i]),
      ),
    );
  }
}

// ─── Product Card ─────────────────────────────────────────────────────────────

class _ProductCard extends StatelessWidget {
  final ProductData product;
  final VoidCallback onTap;
  const _ProductCard({required this.product, required this.onTap});

  bool get _isActive => product.isActive == true;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: _isActive ? Colors.white : const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _isActive ? const Color(0xFFF0F0F0) : const Color(0xFFEEEEEE)),
        boxShadow: _isActive
            ? const [BoxShadow(color: Color(0x06000000), blurRadius: 8, offset: Offset(0, 2))]
            : null,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Icon/avatar
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: _isActive ? AppColors.primary.withAlpha(12) : const Color(0xFFF0F0F0),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  Icons.inventory_2_outlined,
                  size: 18,
                  color: _isActive ? AppColors.primary : const Color(0xFFCCCCCC),
                ),
              ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _isActive ? const Color(0xFF1A1A1A) : const Color(0xFFAAAAAA),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        _SkuBadge(sku: product.skuCode),
                        if (product.categoryName.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          _CategoryBadge(name: product.categoryName),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Status or chevron
              if (!_isActive)
                _StatusBadge(label: 'Nonaktif')
              else
                const Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFFCCCCCC)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SkuBadge extends StatelessWidget {
  final String sku;
  const _SkuBadge({required this.sku});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
    decoration: BoxDecoration(
      color: const Color(0xFFF2F2F2),
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: const Color(0xFFE8E8E8)),
    ),
    child: Text(
      sku,
      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, fontFamily: 'monospace', letterSpacing: 0.5, color: Color(0xFF555555)),
    ),
  );
}

class _CategoryBadge extends StatelessWidget {
  final String name;
  const _CategoryBadge({required this.name});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
    decoration: BoxDecoration(
      color: AppColors.primary.withAlpha(15),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      name,
      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.primary),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    ),
  );
}

class _StatusBadge extends StatelessWidget {
  final String label;
  const _StatusBadge({required this.label});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: const Color(0xFFF2F2F2),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFFAAAAAA))),
  );
}