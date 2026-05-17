import 'package:flutter/material.dart';
import 'package:senkukoadmin/constant/app_colors.dart';
import 'package:senkukoadmin/constant/app_dialog.dart';

class UnsavedChangesDialog {
  static Future<bool> show({
    String title = 'Perubahan Belum Disimpan',
    String message = 'Ada perubahan yang belum disimpan.\nYakin ingin keluar tanpa menyimpan?',
    String confirmLabel = 'Keluar',
    String cancelLabel = 'Tetap di sini',
    Color confirmColor = AppColors.danger,
  }) async {
    return await AppDialog.confirm(
      title: title,
      content: message,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      confirmColor: confirmColor,
    );
  }
}