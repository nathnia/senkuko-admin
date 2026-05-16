import 'package:flutter/material.dart';
import 'package:get/get.dart';

class UnsavedChangesDialog {
  static Future<bool> show({
    String title = 'Perubahan belum disimpan',
    String message = 'Yakin mau keluar? Perubahan akan hilang.',
    String confirmLabel = 'Keluar',
    String cancelLabel = 'Tetap di sini',
  }) async {
    final result = await Get.dialog<bool>(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          title,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        content: Text(
          message,
          style: const TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text(cancelLabel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
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
    );
    return result ?? false;
  }
}