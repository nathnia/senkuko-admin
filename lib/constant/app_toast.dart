// lib/constant/app_toast.dart
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class AppToast {
  AppToast._();

  static void _show(String message) => Fluttertoast.showToast(
        msg: message,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.black54,
        textColor: Colors.white,
        fontSize: 13,
      );

  static void success(String message) => _show('  $message');
  static void error(String message) => _show(' $message');
  static void warning(String message) => _show('  $message');
  static void info(String message) => _show(' $message');
}