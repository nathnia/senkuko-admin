import 'package:flutter/material.dart';
import 'package:senkukoadmin/constant/app_colors.dart';
import 'package:senkukoadmin/features/banners/banner_model.dart';

class BannerCard extends StatelessWidget {
  final BannerData banner;
  final VoidCallback? onToggleStatus;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const BannerCard({
    super.key,
    required this.banner,
    this.onToggleStatus,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = banner.isActive;

    return Opacity(
      opacity: isActive ? 1.0 : 0.5,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Card(
          margin: const EdgeInsets.only(bottom: 8),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.grey.shade100, width: 0.8),
          ),
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // THUMBNAIL
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 64,
                    height: 64,
                    child: banner.imageUrl.isNotEmpty
                        ? Image.network(
                            banner.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _placeholder(),
                            loadingBuilder: (context, child, progress) {
                              if (progress == null) return child;
                              return _placeholder(loading: true);
                            },
                          )
                        : _placeholder(),
                  ),
                ),

                const SizedBox(width: 12),

                // INFO
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              (banner.title != null &&
                                      banner.title!.isNotEmpty)
                                  ? banner.title!
                                  : 'Tanpa judul',
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1A1A1A),
                                height: 1.2,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (onDelete != null)
                            InkWell(
                              onTap: onDelete,
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.all(4),
                                child: Icon(
                                  Icons.delete_outline_rounded,
                                  size: 17,
                                  color: AppColors.danger,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _OrderBadge(order: banner.sortOrder),
                          const SizedBox(width: 6),
                          _StatusPill(isActive: isActive, onTap: onToggleStatus),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _placeholder({bool loading = false}) {
    return Container(
      color: AppColors.successBg,
      alignment: Alignment.center,
      child: Icon(
        loading ? Icons.image_outlined : Icons.broken_image_outlined,
        size: 22,
        color: AppColors.primary,
      ),
    );
  }
}

// ─── Order Badge ───────────────────────────────────────────────────────────

class _OrderBadge extends StatelessWidget {
  final int order;
  const _OrderBadge({required this.order});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'Urutan $order',
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade600,
        ),
      ),
    );
  }
}

// ─── Status Pill ─────────────────────────────────────────────────────────────

class _StatusPill extends StatelessWidget {
  final bool isActive;
  final VoidCallback? onTap;

  const _StatusPill({required this.isActive, this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColors.success : AppColors.danger;
    final bg = isActive ? AppColors.successBg : AppColors.dangerBg;
    final label = isActive ? 'Aktif' : 'Nonaktif';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}