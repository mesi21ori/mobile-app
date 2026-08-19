import 'package:flutter_test/flutter_test.dart';
import 'package:senbet_app/ethiopian_date.dart';

void main() {
  test('Ethiopian new year 2018 is 11 Sep 2025', () {
    final g = EthDate(2018, 1, 1).toGregorian();
    expect(g.year, 2025);
    expect(g.month, 9);
    expect(g.day, 11);
  });

  test('Gregorian 18 Aug 2026 converts and round-trips', () {
    final e = EthDate.fromGregorian(DateTime(2026, 8, 18));
    expect(e.year, 2018);
    final back = e.toGregorian();
    expect(back.year, 2026);
    expect(back.month, 8);
    expect(back.day, 18);
  });
}
