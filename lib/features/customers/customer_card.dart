import 'package:flutter/material.dart';
import 'package:senkukoadmin/constant/app_colors.dart';
import 'package:senkukoadmin/features/customers/customer_model.dart';

class CustomerCard extends StatelessWidget {
  final CustomerData customer;
  final VoidCallback? onToggleStatus;

  const CustomerCard({super.key, required this.customer, this.onToggleStatus});

  _MemberStyle _memberStyle(MemberType type) {
    switch (type) {
      case MemberType.vip:
        return _MemberStyle(
          color: AppColors.warning,
          bg: AppColors.warningBg,
          label: 'VIP',
        );
      case MemberType.member:
        return _MemberStyle(
          color: AppColors.primary,
          bg: AppColors.primary.withAlpha(20),
          label: 'MEMBER',
        );
      case MemberType.regular:
        return _MemberStyle(
          color: AppColors.subtext,
          bg: AppColors.subtext.withAlpha(20),
          label: 'REGULAR',
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final style = _memberStyle(customer.memberType);
    final isActive = customer.isActive;

    return Opacity(
      opacity: isActive ? 1.0 : 0.5,
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.grey.shade100, width: 0.8),
        ),
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              // AVATAR
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: style.bg,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  customer.name.isNotEmpty
                      ? customer.name[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    color: style.color,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
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
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            customer.name,
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1A1A1A),
                              height: 1.2,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        _Badge(style: style),
                      ],
                    ),
                    const SizedBox(height: 4),
                    _SubInfo(customer: customer),
                  ],
                ),
              ),

              const SizedBox(width: 10),

              // STATUS PILL
              _StatusPill(isActive: isActive, onTap: onToggleStatus),
            ],
          ),
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
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

// ─── Member Style ─────────────────────────────────────────────────────────────

class _MemberStyle {
  final Color color;
  final Color bg;
  final String label;
  const _MemberStyle({
    required this.color,
    required this.bg,
    required this.label,
  });
}

// ─── Badge ────────────────────────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  final _MemberStyle style;
  const _Badge({required this.style});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: style.bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        style.label,
        style: TextStyle(
          color: style.color,
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

// ─── Sub Info ─────────────────────────────────────────────────────────────────

class _SubInfo extends StatelessWidget {
  final CustomerData customer;
  const _SubInfo({required this.customer});

  @override
  Widget build(BuildContext context) {
    final parts = <String>[];
    if (customer.phone != null && customer.phone!.isNotEmpty) {
      parts.add(customer.phone!);
    }
    if (customer.email != null && customer.email!.isNotEmpty) {
      parts.add(customer.email!);
    }
    if (parts.isEmpty) return const SizedBox.shrink();
    return Text(
      parts.join('  ·  '),
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: Colors.grey.shade600,
        height: 1.3,
      ),
      overflow: TextOverflow.ellipsis,
    );
  }
}