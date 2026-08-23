class EthPhone {
  static final _local = RegExp(r'^0[79]\d{8}$');
  static final _intl = RegExp(r'^\+251[79]\d{8}$');

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
}
