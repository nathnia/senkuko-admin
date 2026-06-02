import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:senkukoadmin/constant/app_colors.dart';
import 'package:senkukoadmin/constant/app_error_state.dart';
import 'package:senkukoadmin/constant/app_searchbar.dart';
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
    setState(() { _isLoading = true; _hasError = false; });

    if (Get.isRegistered<PromotionController>()) {
      final list = Get.find<PromotionController>().promotionList;
      if (list.isNotEmpty) {
        setState(() { _all = list.toList(); _filtered = _all; _isLoading = false; });
        return;
      }
    }

    try {
      final res = await PromotionService.getAllPromotions();
      if (!mounted) return;
      if (res.statusCode == 200) {
        final data = promotionListModelFromJson(res.body).data;
        setState(() { _all = data; _filtered = data; });
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
          : _all.where((p) =>
              p.name.toLowerCase().contains(_searchQuery) ||
              p.code.toLowerCase().contains(_searchQuery)).toList();
    });
  }

  void _select(PromotionData promo) => Navigator.of(context).pop(promo);

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
            'Pilih Promosi',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
              color: Color(0xFF111111),
            ),
          ),
          const SizedBox(height: 12),
          AppSearchBar(
            hintText: 'Cari nama atau kode promo...',
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
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2.5),
          const SizedBox(height: 12),
          Text('Memuat promosi...', style: TextStyle(fontSize: 13, color: AppColors.subtext)),
        ]),
      );
    }

    if (_hasError) return AppErrorState(message: 'Gagal memuat daftar promosi', onRetry: _load);

    if (_filtered.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 64, height: 64,
            decoration: const BoxDecoration(color: Color(0xFFEAEAEA), shape: BoxShape.circle),
            child: const Icon(Icons.local_offer_outlined, size: 28, color: Color(0xFFCCCCCC)),
          ),
          const SizedBox(height: 12),
          Text(
            _searchQuery.isNotEmpty ? 'Promosi tidak ditemukan' : 'Belum ada promosi',
            style: TextStyle(fontSize: 14, color: AppColors.subtext),
          ),
        ]),
      );
    }

    return ListView.separated(
      controller: sc,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      itemCount: _filtered.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) => _PromoCard(
        promo: _filtered[i],
        onTap: () => _select(_filtered[i]),
      ),
    );
  }
}

// ─── Promotion Card ───────────────────────────────────────────────────────────

class _PromoCard extends StatelessWidget {
  final PromotionData promo;
  final VoidCallback onTap;
  const _PromoCard({required this.promo, required this.onTap});

  bool get _isDimmed => promo.isExpired || !promo.isActive;

  Color get _typeColor {
    switch (promo.type) {
      case 'discount_percent': return const Color(0xFF8B5CF6);
      case 'discount_fixed': return const Color(0xFF0D9488);
      case 'free_item': return const Color(0xFFF97316);
      default: return AppColors.subtext;
    }
  }

  Color get _statusColor {
    if (!promo.isActive) return AppColors.subtext;
    if (promo.isExpired) return const Color(0xFFF97316);
    return AppColors.primary;
  }

  String? get _statusLabel {
    if (promo.isExpired) return 'Kedaluwarsa';
    if (!promo.isActive) return 'Nonaktif';
    return null;
  }

  IconData get _typeIcon {
    switch (promo.type) {
      case 'discount_percent': return Icons.percent_rounded;
      case 'discount_fixed': return Icons.remove_circle_outline_rounded;
      case 'free_item': return Icons.card_giftcard_rounded;
      default: return Icons.local_offer_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('dd MMM yyyy', 'id_ID');
    final label = _statusLabel;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
      ),
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Type icon
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  color: (_isDimmed ? AppColors.subtext : _typeColor).withAlpha(15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _typeIcon,
                  size: 17,
                  color: _isDimmed ? const Color(0xFFCCCCCC) : _typeColor,
                ),
              ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      promo.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _isDimmed ? AppColors.subtext : const Color(0xFF1A1A1A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _CodeBadge(code: promo.code),
                        const SizedBox(width: 6),
                        _TypeBadge(
                          label: promo.typeLabel,
                          color: _isDimmed ? AppColors.subtext : _typeColor,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined, size: 11, color: Color(0xFFCCCCCC)),
                        const SizedBox(width: 5),
                        Text(
                          '${df.format(promo.validFrom)} – ${df.format(promo.validTo)}',
                          style: TextStyle(fontSize: 11, color: AppColors.subtext),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Status or chevron
              if (label != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor.withAlpha(18),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _statusColor),
                  ),
                )
              else
                const Padding(
                  padding: EdgeInsets.only(top: 10),
                  child: Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFFCCCCCC)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Badges ───────────────────────────────────────────────────────────────────

class _CodeBadge extends StatelessWidget {
  final String code;
  const _CodeBadge({required this.code});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
    decoration: BoxDecoration(
      color: AppColors.background,
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      code,
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        fontFamily: 'monospace',
        letterSpacing: 0.5,
        color: AppColors.subtitle,
      ),
    ),
  );
}

class _TypeBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _TypeBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
    decoration: BoxDecoration(
      color: color.withAlpha(18),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      label,
      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color),
    ),
  );
}