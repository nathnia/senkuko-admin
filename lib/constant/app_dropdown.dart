// lib/constant/app_dropdown.dart
import 'package:flutter/material.dart';
import 'package:senkukoadmin/constant/app_colors.dart';

class AppDropdown<T> extends StatelessWidget {
  final String? label;
  final T? value;
  final String? hint;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final bool isRequired;
  final bool enabled;
  final bool showLabel;

  const AppDropdown({
    super.key,
    this.label,
    this.value,
    this.hint,
    required this.items,
    required this.onChanged,
    this.isRequired = false,
    this.enabled = true,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveLabel = label ?? hint;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showLabel && effectiveLabel != null) ...[
            Row(
              children: [
                Text(
                  effectiveLabel,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.subtext,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (isRequired)
                  const Text(
                    ' *',
                    style: TextStyle(color: Colors.red, fontSize: 12),
                  ),
              ],
            ),
            const SizedBox(height: 5),
          ],
          DropdownButtonFormField<T>(
            value: value,
            isExpanded: true,
            hint: hint != null
                ? Text(
                    hint!,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
                  )
                : null,
            items: items,
            onChanged: enabled ? onChanged : null,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
            icon: Icon(
              Icons.arrow_drop_down_rounded,
              color: Colors.grey.shade400,
            ),
            dropdownColor: Colors.white,
            borderRadius: BorderRadius.circular(10),
            decoration: InputDecoration(
              filled: true,
              fillColor: enabled ? Colors.grey.shade100 : Colors.grey.shade200,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: AppColors.primary.withAlpha(80),
                  width: 1.5,
                ),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}