import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:senkukoadmin/constant/app_colors.dart';
import 'package:senkukoadmin/constant/app_error_state.dart';
import 'package:senkukoadmin/constant/app_searchbar.dart';
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
      if (ctrl.hasError.value) {
        setState(() => _hasError = true);
      } else {
        final list = ctrl.productList;
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
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFE0E0E0),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 14),
          // Title centered, close button absolute-style via Stack
          Stack(
            alignment: Alignment.center,
            children: [
              const Text(
                'Pilih Produk',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111111),
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Search bar
          AppSearchBar(
            hintText: 'Cari nama atau SKU...',
            onChanged: _onSearchChanged,
            textController: _searchC,
          ),
        ],
      ),
    );
  }

  Widget _buildBody(ScrollController sc) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              color: AppColors.primary,
              strokeWidth: 2.5,
            ),
            const SizedBox(height: 12),
            const Text(
              'Memuat produk...',
              style: TextStyle(fontSize: 13, color: Color(0xFFAAAAAA)),
            ),
          ],
        ),
      );
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
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: Color(0xFFF2F2F2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.inventory_2_outlined,
                size: 32,
                color: Color(0xFFCCCCCC),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Produk tidak ditemukan'
                  : 'Belum ada produk',
              style: const TextStyle(fontSize: 14, color: Color(0xFFAAAAAA)),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: sc,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 24),
      itemCount: _filtered.length,
      itemBuilder: (_, i) => _ProductCard(
        product: _filtered[i],
        onTap: () => _select(_filtered[i]),
      ),
    );
  }
}

// ─── Product Card ──────────────────────────────────────────────────────────────

class _ProductCard extends StatelessWidget {
  final ProductData product;
  final VoidCallback onTap;
  const _ProductCard({required this.product, required this.onTap});

  String? get _firstImageUrl {
    final imgs = product.images;
    if (imgs == null || imgs.isEmpty) return null;
    final primary = imgs.where((i) => i.isPrimary).firstOrNull;
    return primary?.imageUrl ?? imgs.first.imageUrl;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildThumbnail(),
              const SizedBox(width: 12),
              Expanded(child: _buildInfo()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail() {
    final url = _firstImageUrl;
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: 72,
        child: url != null && url.isNotEmpty
            ? Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _placeholder(),
                loadingBuilder: (_, child, progress) =>
                    progress == null ? child : _placeholder(),
              )
            : _placeholder(),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: 72,
      color: AppColors.background,
      child: Icon(Icons.image_outlined, color: AppColors.subtext, size: 22),
    );
  }

  Widget _buildInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              product.name,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Colors.black87,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              product.categoryName,
              style: TextStyle(fontSize: 12, color: AppColors.subtext),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        const SizedBox(height: 8),
        _SkuBadge(sku: product.skuCode),
      ],
    );
  }
}

class _SkuBadge extends StatelessWidget {
  final String sku;
  const _SkuBadge({required this.sku});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      color: AppColors.background,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      sku,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: AppColors.subtext,
      ),
    ),
  );
}
