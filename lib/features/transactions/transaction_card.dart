import 'package:flutter/material.dart';
import 'package:senkukoadmin/constant/app_colors.dart';
import 'package:senkukoadmin/features/transactions/transaction_model.dart';

class TransactionCard extends StatelessWidget {
  final TransactionData transaction;
  final VoidCallback onTap;

  const TransactionCard({
    super.key,
    required this.transaction,
    required this.onTap,
  });

  Color _methodColor(String method) {
    switch (method) {
      case 'cash':
        return const Color(0xFF2DC98E);
      case 'transfer':
        return const Color(0xFF4F7EFF);
      case 'qris':
        return const Color(0xFF9B6DFF);
      default:
        return Colors.grey;
    }
  }

  Color _methodBg(String method) {
    switch (method) {
      case 'cash':
        return const Color(0xFFE8FAF3);
      case 'transfer':
        return const Color(0xFFEEF3FF);
      case 'qris':
        return const Color(0xFFF3EEFF);
      default:
        return Colors.grey.shade100;
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return '${date.day} ${months[date.month]} ${date.year} • ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _methodBg(transaction.paymentMethod),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                transaction.paymentMethod == 'cash'
                    ? Icons.payments_outlined
                    : transaction.paymentMethod == 'transfer'
                        ? Icons.account_balance_outlined
                        : Icons.qr_code_outlined,
                color: _methodColor(transaction.paymentMethod),
                size: 18,
              ),
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.invoiceNumber,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    transaction.customerName ?? 'Pelanggan umum',
                    style: TextStyle(
                      fontSize: 11,
                      color: transaction.customerName != null
                          ? Colors.grey.shade700
                          : Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _formatDate(transaction.transactedAt),
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ],
              ),
            ),

            // Amount + method
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  transaction.formattedGrandTotal,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _methodBg(transaction.paymentMethod),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    transaction.paymentMethodLabel,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: _methodColor(transaction.paymentMethod),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(width: 6),
            Icon(Icons.chevron_right, size: 16, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}