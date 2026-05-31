import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:senkukoadmin/constant/app_colors.dart';
import 'package:senkukoadmin/constant/app_error_state.dart';
import 'package:senkukoadmin/features/promotions/promotion_model.dart';
import 'package:senkukoadmin/features/promotions/promotion_controller.dart';
import 'package:senkukoadmin/features/promotions/promotion_service.dart';

class PromotionPickerSheet extends StatefulWidget {
  const PromotionPickerSheet({super.key});

  static Future<PromotionData?> show(BuildContext context) {
    return showModalBottomSheet<PromotionData>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (_) => const PromotionPickerSheet(),
    );
  }

  @override
  State<PromotionPickerSheet> createState() => _PromotionPickerSheetState();
}

class _PromotionPickerSheetState extends State<PromotionPickerSheet> {
  late final DraggableScrollableController _sheetC;
  late final TextEditingController _searchC;

  List<PromotionData> _all = [];
  List<PromotionData> _filtered = [];
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

    // Reuse already-loaded list if PromotionController is registered
    if (Get.isRegistered<PromotionController>()) {
      final list = Get.find<PromotionController>().promotionList;
      if (list.isNotEmpty) {
        setState(() {
          _all = list.toList();
          _filtered = _all;
          _isLoading = false;
        });
        return;
      }
    }

    // Otherwise fetch directly
    try {
      final res = await PromotionService.getAllPromotions();
      if (!mounted) return;
      if (res.statusCode == 200) {
        final data = promotionListModelFromJson(res.body).data;
        setState(() {
          _all = data;
          _filtered = data;
        });
      } else {
        setState(() => _hasError = true);
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
                    p.code.toLowerCase().contains(_searchQuery),
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

  void _select(PromotionData promo) => Navigator.of(context).pop(promo);

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

          // Title
          const Center(
            child: Text(
              'Pilih Promosi',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
          ),
          const SizedBox(height: 10),

          // Search bar
          TextField(
            controller: _searchC,
            onChanged: _onSearchChanged,
            onTap: _expandSheet,
            decoration: InputDecoration(
              hintText: 'Cari nama atau kode promo...',
              hintStyle:
                  TextStyle(fontSize: 13, color: Colors.grey.shade400),
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

  // ── Body ────────────────────────────────────────────────────────────────

  Widget _buildBody(ScrollController scrollController) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_hasError) {
      return AppErrorState(
        message: 'Gagal memuat daftar promosi',
        onRetry: _load,
      );
    }

    if (_filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.local_offer_outlined,
                size: 40, color: Colors.grey.shade300),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Promosi tidak ditemukan'
                  : 'Belum ada promosi',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: scrollController,
      itemCount: _filtered.length,
      itemBuilder: (_, i) => _PromoTile(
        promo: _filtered[i],
        onTap: () => _select(_filtered[i]),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// PROMO TILE
// ═══════════════════════════════════════════════════════════════

class _PromoTile extends StatelessWidget {
  final PromotionData promo;
  final VoidCallback onTap;

  const _PromoTile({required this.promo, required this.onTap});

  Color get _typeBadgeColor {
    switch (promo.type) {
      case 'discount_percent':
        return Colors.purple;
      case 'discount_fixed':
        return Colors.teal;
      case 'free_item':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Color get _statusColor {
    if (!promo.isActive) return Colors.grey;
    if (promo.isExpired) return Colors.orange;
    return AppColors.primary;
  }

  String? get _statusLabel {
    if (promo.isExpired) return 'Kedaluwarsa';
    if (!promo.isActive) return 'Nonaktif';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('dd MMM yyyy', 'id_ID');
    final isDimmed = promo.isExpired || !promo.isActive;
    final label = _statusLabel;

    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // Info column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        promo.name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isDimmed
                              ? Colors.grey.shade400
                              : Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _badge(
                            label: promo.code,
                            bg: Colors.grey.shade100,
                            fg: Colors.black87,
                            border: Colors.grey.shade300,
                            mono: true,
                          ),
                          const SizedBox(width: 5),
                          _badge(
                            label: promo.typeLabel,
                            bg: _typeBadgeColor.withAlpha(20),
                            fg: _typeBadgeColor,
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 10,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${df.format(promo.validFrom)} – ${df.format(promo.validTo)}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Right: status badge OR chevron
                if (label != null)
                  _badge(
                    label: label,
                    bg: _statusColor.withAlpha(20),
                    fg: _statusColor,
                  )
                else
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: Colors.grey.shade400,
                  ),
              ],
            ),
          ),
        ),
        Divider(height: 1, color: Colors.grey.shade100),
      ],
    );
  }

  Widget _badge({
    required String label,
    required Color bg,
    required Color fg,
    Color? border,
    bool mono = false,
  }) =>
      Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(4),
          border:
              border != null ? Border.all(color: border, width: 0.5) : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: fg,
            fontFamily: mono ? 'monospace' : null,
            letterSpacing: mono ? 0.5 : null,
          ),
        ),
      );
}