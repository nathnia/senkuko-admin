import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const primary = Color.fromARGB(255, 76, 176, 80);
  static const secondary = Color(0xFF3B82F6);
  static const secondaryBg = Color(0xFFEEF3FF); // bg badge/pill secondary

  static const background = Color(0xFFF5F5F5);
  static const card = Colors.white;

  // Text
  static const title = Color(
    0xFF1A1A2E,
  ); // heading, invoice number, nilai utama
  static const subtitle = Color.fromARGB(255, 79, 79, 79);
  static const subtext = Color(0xFF9E9E9E); // label, placeholder, info sekunder

  // Semantic
  static const success = Color(0xFF3B6D11); // fg
  static const successBg = Color(0xFFE8F5E0); // bg badge

  static const warning = Color(0xFF854F0B); // fg
  static const warningBg = Color(0xFFFAEEDA); // bg badge

  static const danger = Color(
    0xFFA32D2D,
  ); // fg — juga dipakai untuk diskon/negatif
  static const dangerBg = Color(0xFFFCEBEB); // bg badge

  static const Color shipped = Color.fromARGB(255, 76, 176, 80);
  static const Color shippedBg = Color(0xFFF0EAFA);
  static const Color neutralBg = Color(0xFFF3F4F6); // untuk cancelled, default
}
