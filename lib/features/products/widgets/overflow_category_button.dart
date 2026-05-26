import 'package:flutter/material.dart';
import 'package:senkukoadmin/constant/app_colors.dart';

class OverflowCategoryButton extends StatelessWidget {
  final List<String> overflowTabs;
  final String selectedTab;
  final VoidCallback onTap;

  const OverflowCategoryButton({
    super.key,
    required this.overflowTabs,
    required this.selectedTab,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final overflowActive = overflowTabs.contains(selectedTab);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: overflowActive ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: overflowActive ? AppColors.primary : Colors.grey.shade300,
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              overflowActive ? selectedTab : 'Lainnya',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: overflowActive ? Colors.white : AppColors.subtitle
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.expand_more_rounded,
              size: 16,
              color: overflowActive ? Colors.white : Colors.black54,
            ),
          ],
        ),
      ),
    );
  }
}