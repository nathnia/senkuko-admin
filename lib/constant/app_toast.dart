import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class AppToast {
  AppToast._();

  static void show(String message) {
    if (message.trim().isEmpty) return;
    Fluttertoast.showToast(
      msg: message,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: const Color(0xFF3A3A3A),
      textColor: Colors.white,
      fontSize: 13,
    );
  }
}
