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
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isActive
                  ? AppColors.primary.withOpacity(0.1)
                  : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: isActive
                  ? Border.all(color: AppColors.primary, width: 1.5)
                  : null,
            ),
            child: Icon(
              Icons.tune_rounded,
              size: 20,
              color: isActive ? AppColors.primary : Colors.black87,
            ),
          ),
          if (isActive)
            Positioned(
              right: 5,
              top: 5,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}