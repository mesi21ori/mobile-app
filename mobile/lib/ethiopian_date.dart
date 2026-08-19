import 'package:flutter/material.dart';
import 'theme.dart';

/// Ethiopian calendar (13 months) with conversion to/from Gregorian.
class EthDate {
  const EthDate(this.year, this.month, this.day);
  final int year;
  final int month;
  final int day;

  static const months = [
    'መስከረም',
    'ጥቅምት',
    'ኅዳር',
    'ታኅሣሥ',
    'ጥር',
    'የካቲት',
    'መጋቢት',
    'ሚያዝያ',
    'ግንቦት',
    'ሰኔ',
    'ሐምሌ',
    'ነሐሴ',
    'ጳጉሜን',
  ];

  static const weekdays = ['እሑድ', 'ሰኞ', 'ማክሰኞ', 'ረቡዕ', 'ሐሙስ', 'አርብ', 'ቅዳሜ'];

  bool get isLeap => year % 4 == 3;

  int get daysInMonth {
    if (month < 13) return 30;
    return isLeap ? 6 : 5;
  }

  DateTime toGregorian() {
    final j = _ethToJdn(year, month, day);
    return _jdnToGregorian(j);
  }

  String get label => '$day $monthName $year ዓ.ም.';
  String get monthName => months[month - 1];

  /// 0 = እሑድ … 6 = ቅዳሜ
  int get weekdayIndex {
    final g = toGregorian();
    return g.weekday % 7;
  }

  static EthDate now() => fromGregorian(DateTime.now());

  static EthDate fromGregorian(DateTime d) {
    final local = DateTime(d.year, d.month, d.day);
    return _jdnToEth(_gregorianToJdn(local.year, local.month, local.day));
  }

  static EthDate? tryParse(dynamic value) {
    if (value == null) return null;
    final dt = DateTime.tryParse(value.toString());
    if (dt == null) return null;
    return fromGregorian(dt.toLocal());
  }

  static String format(dynamic value, {String fallback = ''}) {
    return tryParse(value)?.label ?? fallback;
  }

  static int daysUntil(dynamic value) {
    final e = tryParse(value);
    if (e == null) return 0;
    final due = DateTime(e.toGregorian().year, e.toGregorian().month, e.toGregorian().day);
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    return due.difference(today).inDays;
  }

  static String remainingLabel(dynamic value) {
    final days = daysUntil(value);
    if (days > 0) return 'ቀርቷል · ${_span(days)}';
    if (days == 0) return 'ዛሬ መመለስ አለበት';
    return 'አልፏል · ${_span(-days)}';
  }

  static String _span(int days) {
    if (days >= 30) {
      final months = days ~/ 30;
      final rest = days % 30;
      if (rest == 0) return '$months ወር';
      return '$months ወር $rest ቀን';
    }
    return '$days ቀን';
  }

  static bool inThisMonth(dynamic value) {
    final e = tryParse(value);
    if (e == null) return false;
    final n = now();
    return e.year == n.year && e.month == n.month;
  }

  static bool inMonth(dynamic value, EthDate month) {
    final e = tryParse(value);
    if (e == null) return false;
    return e.year == month.year && e.month == month.month;
  }

  static EthDate _jdnToEth(int jdn) {
    final r = (jdn - 1723856) % 1461;
    final n = (r % 365) + 365 * (r ~/ 1460);
    final year = 4 * ((jdn - 1723856) ~/ 1461) + (r ~/ 365) - (r ~/ 1460);
    final month = n ~/ 30 + 1;
    final day = n % 30 + 1;
    return EthDate(year, month, day);
  }
}

int _gregorianToJdn(int year, int month, int day) {
  final a = ((14 - month) ~/ 12);
  final y = year + 4800 - a;
  final m = month + 12 * a - 3;
  return day + ((153 * m + 2) ~/ 5) + 365 * y + y ~/ 4 - y ~/ 100 + y ~/ 400 - 32045;
}

int _ethToJdn(int year, int month, int day) {
  return 1723856 + 365 + 365 * (year - 1) + (year ~/ 4) + 30 * month + day - 31;
}

DateTime _jdnToGregorian(int jdn) {
  var l = jdn + 68569;
  final n = (4 * l) ~/ 146097;
  l = l - (146097 * n + 3) ~/ 4;
  final i = (4000 * (l + 1)) ~/ 1461001;
  l = l - (1461 * i) ~/ 4 + 31;
  final j = (80 * l) ~/ 2447;
  final day = l - (2447 * j) ~/ 80;
  l = j ~/ 11;
  final month = j + 2 - 12 * l;
  final year = 100 * (n - 49) + i + l;
  return DateTime(year, month, day);
}

Future<DateTime?> pickEthiopianDate(
  BuildContext context, {
  DateTime? initial,
}) async {
  var current = EthDate.fromGregorian(initial ?? DateTime.now());
  return showModalBottomSheet<DateTime>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setS) {
          final days = current.daysInMonth;
          return Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 18),
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(color: AppTheme.seed.withValues(alpha: 0.12), blurRadius: 30, offset: const Offset(0, 12)),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(color: AppTheme.blueSoft, borderRadius: BorderRadius.circular(4)),
                ),
                const Text('የኢትዮጵያ ቀን መቁጠሪያ', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    IconButton(
                      onPressed: () => setS(() => current = EthDate(current.year - 1, current.month, 1)),
                      icon: const Icon(Icons.keyboard_double_arrow_left_rounded),
                    ),
                    IconButton(
                      onPressed: () {
                        var m = current.month - 1;
                        var y = current.year;
                        if (m < 1) {
                          m = 13;
                          y--;
                        }
                        setS(() => current = EthDate(y, m, 1));
                      },
                      icon: const Icon(Icons.chevron_left_rounded),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            current.monthName,
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppTheme.seed),
                          ),
                          Text('${current.year} ዓ.ም.', style: const TextStyle(color: AppTheme.muted, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        var m = current.month + 1;
                        var y = current.year;
                        if (m > 13) {
                          m = 1;
                          y++;
                        }
                        setS(() => current = EthDate(y, m, 1));
                      },
                      icon: const Icon(Icons.chevron_right_rounded),
                    ),
                    IconButton(
                      onPressed: () => setS(() => current = EthDate(current.year + 1, current.month, 1)),
                      icon: const Icon(Icons.keyboard_double_arrow_right_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: EthDate.weekdays
                      .map((w) => Expanded(
                            child: Text(w, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: AppTheme.muted, fontWeight: FontWeight.w700)),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 8),
                Builder(
                  builder: (_) {
                    final lead = EthDate(current.year, current.month, 1).weekdayIndex;
                    final today = EthDate.now();
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: lead + days,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 7,
                        mainAxisSpacing: 6,
                        crossAxisSpacing: 6,
                      ),
                      itemBuilder: (_, i) {
                        if (i < lead) return const SizedBox.shrink();
                        final day = i - lead + 1;
                        final selected = day == current.day;
                        final isToday = today.year == current.year && today.month == current.month && today.day == day;
                        return InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () => setS(() => current = EthDate(current.year, current.month, day)),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeOutCubic,
                            decoration: BoxDecoration(
                              color: selected ? AppTheme.seed : (isToday ? AppTheme.blueSoft : AppTheme.mist),
                              borderRadius: BorderRadius.circular(14),
                              border: isToday && !selected ? Border.all(color: AppTheme.blue) : null,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '$day',
                              style: TextStyle(
                                color: selected ? Colors.white : AppTheme.ink,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 14),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, current.toGregorian()),
                  child: Text('${current.label} · ምረጥ'),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}
