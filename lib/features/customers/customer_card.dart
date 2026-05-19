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
        return _MemberStyle(color: AppColors.secondary, label: 'VIP');
      case MemberType.member:
        return _MemberStyle(color: AppColors.primary, label: 'MEMBER');
      case MemberType.regular:
        return _MemberStyle(color: const Color(0xFF9E9E9E), label: 'REGULAR');
    }
  }

  @override
  Widget build(BuildContext context) {
    final style = _memberStyle(customer.memberType);
    final isActive = customer.isActive;

    return Opacity(
      opacity: isActive ? 1.0 : 0.45,
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade100, width: 0.5),
        ),
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
          child: Row(
            children: [
              // AVATAR
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: style.color.withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  customer.name.isNotEmpty
                      ? customer.name[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    color: style.color,
                    fontWeight: FontWeight.w600,
                    fontSize: 17,
                  ),
                ),
              ),

              const SizedBox(width: 11),

              // INFO — nama + badge + kontak saja, no spending
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            customer.name,
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w500,
                              height: 1.2,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        _Badge(style: style),
                      ],
                    ),
                    const SizedBox(height: 3),
                    _SubInfo(customer: customer),
                  ],
                ),
              ),

              const SizedBox(width: 10),

              // STATUS PILL — menggantikan Switch
              _StatusPill(isActive: isActive, onTap: onToggleStatus),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Status Pill ────────────────────────────────────────────────────────────

class _StatusPill extends StatelessWidget {
  final bool isActive;
  final VoidCallback? onTap;

  const _StatusPill({required this.isActive, this.onTap});

  @override
  Widget build(BuildContext context) {
    final borderColor = isActive ? AppColors.primary : AppColors.danger;
    final textColor = isActive ? AppColors.primary : AppColors.danger;
    final dotColor = isActive ? AppColors.primary : AppColors.danger;
    final label = isActive ? 'Aktif' : 'Dinonaktifkan';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor.withAlpha(60), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Member Style ────────────────────────────────────────────────────────────

class _MemberStyle {
  final Color color;
  final String label;
  const _MemberStyle({required this.color, required this.label});
}

// ─── Badge ───────────────────────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  final _MemberStyle style;
  const _Badge({required this.style});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: style.color.withAlpha(18),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            style.label,
            style: TextStyle(
              color: style.color,
              fontSize: 9,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Sub Info ────────────────────────────────────────────────────────────────

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
      style: const TextStyle(fontSize: 11, color: Colors.grey),
      overflow: TextOverflow.ellipsis,
    );
  }
}
