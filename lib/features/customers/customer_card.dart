import 'package:flutter/material.dart';
import 'package:senkukoadmin/constant/app_colors.dart';
import 'package:senkukoadmin/constant/currency_formatter.dart';
import 'package:senkukoadmin/features/customers/customer_model.dart';

class CustomerCard extends StatelessWidget {
  final CustomerData customer;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const CustomerCard({
    super.key,
    required this.customer,
    this.onTap,
    this.onDelete,
  });

  _MemberStyle _memberStyle(String type) {
    switch (type) {
      case 'vip':
        return _MemberStyle(
          color: AppColors.secondary,
          label: 'VIP',
          icon: Icons.workspace_premium_rounded,
        );
      case 'member':
        return _MemberStyle(
          color: AppColors.primary,
          label: 'MEMBER',
          icon: Icons.card_membership_rounded,
        );
      default:
        return _MemberStyle(
          color: const Color(0xFF9E9E9E),
          label: 'REGULAR',
          icon: Icons.person_rounded,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final style = _memberStyle(customer.memberType);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.grey.shade100, width: 1),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            // AVATAR
            Container(
              width: 40,
              height: 40,
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
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                ),
              ),
            ),
      
            const SizedBox(width: 10),
      
            // INFO
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Name + Badge inline
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          customer.name,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
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
      
                  // Phone / email in one line, separated by dot
                  _SubInfo(customer: customer),
      
                  const SizedBox(height: 2),
      
                  // Total belanja
                  Text(
                   CurrencyFormatter.format(customer.totalSpend),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: style.color,
                    ),
                  ),
                ],
              ),
            ),
      
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') onTap?.call();
                if (value == 'delete') onDelete?.call();
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 16),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 16, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Hapus', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
              icon: const Icon(Icons.more_vert, size: 18, color: Colors.grey),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }
}

class _MemberStyle {
  final Color color;
  final String label;
  final IconData icon;
  const _MemberStyle({
    required this.color,
    required this.label,
    required this.icon,
  });
}

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
          Icon(style.icon, size: 9, color: style.color),
          const SizedBox(width: 3),
          Text(
            style.label,
            style: TextStyle(
              color: style.color,
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

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