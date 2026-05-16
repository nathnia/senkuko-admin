import 'package:flutter/material.dart';
import 'package:senkukoadmin/constant/app_colors.dart';

class AppSearchBar extends StatelessWidget {
  final String hintText;
  final ValueChanged<String> onChanged;
  final TextEditingController? textController;

  const AppSearchBar({
    super.key,
    required this.hintText,
    required this.onChanged,
    this.textController,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: TextField(
        controller: textController,
        onChanged: onChanged,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(fontSize: 14, color: Colors.grey.shade400),
          prefixIcon: Icon(
            Icons.search_rounded,
            size: 18,
            color: Colors.grey.shade400,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200, width: 0.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200, width: 0.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: AppColors.primary.withAlpha(80),
              width: 1,
            ),
          ),
        ),
      ),
    );
  }
}