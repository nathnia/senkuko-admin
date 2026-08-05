import 'package:flutter/material.dart';
import 'package:senkukoadmin/constant/app_colors.dart';

class AppFilterButton extends StatelessWidget {
  final bool isActive;
  final VoidCallback onTap;

  const AppFilterButton({
    super.key,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary.withAlpha(20) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? AppColors.primary : Colors.grey.shade200,
            width: isActive ? 1.5 : 0.5,
          ),
        ),
        child: Center(
          child: Icon(
            Icons.tune_rounded,
            size: 20,
            color: isActive ? AppColors.primary : AppColors.subtitle,
          ),
        ),
      ),
    );
  }
}