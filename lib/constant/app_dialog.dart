import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:senkukoadmin/constant/app_colors.dart';

class AppDialog {
  static Future<bool> confirm({
    required String title,
    required String content,
    String cancelLabel = 'Batal',
    String confirmLabel = 'Ya, Hapus',
    Color confirmColor = AppColors.danger,
    bool barrierDismissible = false,
  }) async {
    return await Get.dialog<bool>(
          AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            title: Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            content: Text(
              content,
              style: const TextStyle(fontSize: 13),
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(result: false),
                child: Text(cancelLabel),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: confirmColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () => Get.back(result: true),
                child: Text(
                  confirmLabel,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          barrierDismissible: barrierDismissible,
        ) ??
        false;
  }
}