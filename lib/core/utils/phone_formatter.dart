// KANAWA - Formatação de telefone angolano (+244)

import 'package:flutter/services.dart';

/// Formata o número enquanto o utilizador escreve: 923 456 789
class AngolaPhoneFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final buffer = StringBuffer();

    for (int i = 0; i < digits.length && i < 9; i++) {
      if (i == 3 || i == 6) buffer.write(' ');
      buffer.write(digits[i]);
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// Normaliza para formato +244XXXXXXXXX
String normalizeAngolaPhone(String input) {
  final digits = input.replaceAll(RegExp(r'\D'), '');
  if (digits.startsWith('244')) return '+$digits';
  if (digits.length == 9) return '+244$digits';
  return '+244$digits';
}