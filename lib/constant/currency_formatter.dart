// lib/core/utils/currency_formatter.dart
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final _formatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp',
    decimalDigits: 0,
  );

  static String format(dynamic value) {
    final amount = double.tryParse(value.toString()) ?? 0;
    return _formatter.format(amount);
  }
}

class CurrencyInputFormatter extends TextInputFormatter {
  final _formatter = NumberFormat('#,###', 'id_ID');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Kalau kosong, biarkan kosong
    if (newValue.text.isEmpty) return newValue;

    // Hapus semua karakter selain angka
    final digits = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.isEmpty) return newValue.copyWith(text: '');

    final number = int.tryParse(digits) ?? 0;
    final formatted = _formatter.format(number);

    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}