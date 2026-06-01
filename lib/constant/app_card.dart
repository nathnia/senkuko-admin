import 'package:flutter/material.dart';
import 'package:senkukoadmin/constant/app_colors.dart';

class AppCard extends StatelessWidget {
  final String? title;
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final String? actionLabel;
  final VoidCallback? onAction;

  const AppCard({
    super.key,
    this.title,
    required this.child,
    this.padding,
    this.margin,
    this.actionLabel,
    this.onAction,
  }) : assert(
          actionLabel == null || onAction != null,
          'onAction is required when actionLabel is provided',
        );

  @override
  Widget build(BuildContext context) {
    final bool hasAction = actionLabel != null && onAction != null;

    return Container(
      width: double.infinity,
      margin: margin,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade100, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title!,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.black54,
                    letterSpacing: 0.5,
                  ),
                ),
                if (hasAction)
                  GestureDetector(
                    onTap: onAction,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.add_rounded, size: 13, color: Colors.white),
                          const SizedBox(width: 4),
                          Text(
                            actionLabel!,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
          ],
          child,
        ],
      ),
    );
  }
}