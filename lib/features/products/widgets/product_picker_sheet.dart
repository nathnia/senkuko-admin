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
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    if (Get.isRegistered<ProductController>()) {
      final list = Get.find<ProductController>().productList;
      if (list.isNotEmpty) {
        setState(() {
          _all = list.toList();
          _filtered = _all;
          _isLoading = false;
        });
        return;
      }
    }

    try {
      final ctrl = Get.find<ProductController>();
      await ctrl.fetchProducts();
      if (!mounted) return;
      final list = ctrl.productList;
      if (ctrl.hasError.value) {
        setState(() => _hasError = true);
      } else {
        setState(() {
          _all = list.toList();
          _filtered = _all;
        });
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
          : _all
              .where(
                (p) =>
                    p.name.toLowerCase().contains(_searchQuery) ||
                    p.skuCode.toLowerCase().contains(_searchQuery),
              )
              .toList();
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

  void _select(ProductData product) => Navigator.of(context).pop(product);

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
          const Center(
            child: Text(
              'Pilih Produk',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _searchC,
            onChanged: _onSearchChanged,
            onTap: _expandSheet,
            decoration: InputDecoration(
              hintText: 'Cari nama atau SKU...',
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
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_hasError) {
      return AppErrorState(
        message: 'Gagal memuat daftar produk',
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
                  ? 'Produk tidak ditemukan'
                  : 'Belum ada produk',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: scrollController,
      itemCount: _filtered.length,
      itemBuilder: (_, i) => _ProductTile(
        product: _filtered[i],
        onTap: () => _select(_filtered[i]),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// PRODUCT TILE
// ═══════════════════════════════════════════════════════════════

class _ProductTile extends StatelessWidget {
  final ProductData product;
  final VoidCallback onTap;

  const _ProductTile({required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDimmed = product.isActive != true;

    return Column(
      children: [
        InkWell(
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
                        product.name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isDimmed ? Colors.grey.shade400 : Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _skuBadge(product.skuCode),
                          if (product.categoryName.isNotEmpty) ...[
                            const SizedBox(width: 5),
                            _categoryBadge(product.categoryName),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (product.isActive != true)
                  _statusBadge('Nonaktif', Colors.grey)
                else
                  Icon(Icons.chevron_right_rounded,
                      size: 18, color: Colors.grey.shade400),
              ],
            ),
          ),
        ),
        Divider(height: 1, color: Colors.grey.shade100),
      ],
    );
  }

  Widget _skuBadge(String sku) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.grey.shade300, width: 0.5),
        ),
        child: Text(
          sku,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            fontFamily: 'monospace',
            letterSpacing: 0.5,
          ),
        ),
      );

  Widget _categoryBadge(String name) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.primary.withAlpha(15),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          name,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
      );

  Widget _statusBadge(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      );
}