import 'package:flutter/material.dart';
import 'package:senkukoadmin/constant/app_colors.dart';

class AppSaveButton extends StatelessWidget {
  final VoidCallback? onTap;
  final bool isLoading;
  final bool isDisabled;
  final String label;

  const AppSaveButton({
    super.key,
    required this.onTap,
    this.isLoading = false,
    this.isDisabled = false,
    this.label = 'Simpan',
  });

  @override
  Widget build(BuildContext context) {
    final bool disabled = isDisabled || isLoading;

    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 16, top: 10, bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        decoration: BoxDecoration(
          color: disabled ? Colors.grey.shade300 : AppColors.primary,
          borderRadius: BorderRadius.circular(10),
        ),
        child: isLoading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }
}