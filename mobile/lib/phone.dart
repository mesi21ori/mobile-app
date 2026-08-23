import 'package:flutter/services.dart';

class EthPhone {
  static final _local = RegExp(r'^0[79]\d{8}$');
  static final _intl = RegExp(r'^\+251[79]\d{8}$');
  static const _intlPrefix = '+251';

  static bool isValid(String? raw) {
    final s = raw?.trim() ?? '';
    if (s.isEmpty) return false;
    return _local.hasMatch(s) || _intl.hasMatch(s);
  }

  static String? validate(String? raw, {bool required = true}) {
    final s = raw?.trim() ?? '';
    if (s.isEmpty) return required ? 'ስልክ ያስፈልጋል' : null;
    if (isValid(s)) return null;
    return '0975989898 ወይም +251975989898';
  }

  static bool allowsPartial(String text) {
    final s = text.trim();
    if (s.isEmpty) return true;
    if (s.startsWith('+')) {
      if (s.length <= _intlPrefix.length) return _intlPrefix.startsWith(s);
      if (!s.startsWith(_intlPrefix)) return false;
      final rest = s.substring(_intlPrefix.length);
      if (rest.isEmpty) return true;
      if (rest.length == 1) return '79'.contains(rest[0]);
      return RegExp(r'^[79]\d{0,8}$').hasMatch(rest);
    }
    if (s == '0') return true;
    if (s.length == 2) return RegExp(r'^0[79]$').hasMatch(s);
    if (s.startsWith('0') && s.length > 1 && !'79'.contains(s[1])) return false;
    return RegExp(r'^0[79]\d{0,8}$').hasMatch(s);
  }
}

class EthPhoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var text = newValue.text.replaceAll(RegExp(r'[^\d+]'), '');
    if (text.contains('+')) {
      if (!text.startsWith('+')) return oldValue;
      text = '+${text.substring(1).replaceAll('+', '')}';
    }
    if (text.startsWith('+')) {
      if (text.length > 13) text = text.substring(0, 13);
    } else if (text.length > 10) {
      text = text.substring(0, 10);
    }
    if (!EthPhone.allowsPartial(text)) return oldValue;
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
