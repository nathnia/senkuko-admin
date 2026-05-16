import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final _formatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  static String format(dynamic value) {
    final amount = double.tryParse(value.toString()) ?? 0;
    return _formatter.format(amount);
  }
}

class DateFormatter {
  static final _dateTime = DateFormat("d MMM yyyy '•' HH:mm", 'id_ID');

  static final _dateTimeNoSep = DateFormat('d MMM yyyy HH:mm', 'id_ID');

  static final _short = DateFormat('d MMM', 'id_ID');

  static String formatDateTime(DateTime date) => _dateTime.format(date);

  static String formatDateTimeRaw(String raw) {
    final date = DateTime.tryParse(raw);
    if (date == null) return raw;
    return _dateTimeNoSep.format(date);
  }

  static String formatShort(DateTime date) => _short.format(date);
}

class CurrencyInputFormatter extends TextInputFormatter {
  final _formatter = NumberFormat('#,###', 'id_ID');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;
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