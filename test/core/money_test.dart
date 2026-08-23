import 'package:flutter_test/flutter_test.dart';
import 'package:trading_app/core/money/money.dart';
import 'package:trading_app/core/utils/formatters.dart';

void main() {
  group('Money Value Object Tests', () {
    test('creates Money from paise and rupees correctly', () {
      final m1 = Money(285035);
      final m2 = Money.fromRupees(2850.35);

      expect(m1.paise, equals(285035));
      expect(m2.paise, equals(285035));
      expect(m1.toRupees, equals(2850.35));
      expect(m1.rupees, equals(2850));
      expect(m1.remainingPaise, equals(35));
    });

    test('performs addition and subtraction accurately', () {
      final a = Money(100000); // ₹1000.00
      final b = Money(50025);  // ₹500.25

      final sum = a + b;
      final diff = a - b;

      expect(sum.paise, equals(150025));
      expect(sum.toRupees, equals(1500.25));
      expect(diff.paise, equals(49975));
      expect(diff.toRupees, equals(499.75));
    });

    test('multiplies quantity without floating-point artifacts', () {
      final price = Money(285035); // ₹2850.35
      const qty = 3;

      final total = price * qty; // 285035 * 3 = 855105 paise = ₹8551.05

      expect(total.paise, equals(855105));
      expect(total.toRupees, equals(8551.05));
      expect(total.format(), contains('8,551.05'));
    });

    test('compares Money objects correctly', () {
      final m1 = Money(100);
      final m2 = Money(200);
      final m3 = Money(100);

      expect(m1 < m2, isTrue);
      expect(m2 > m1, isTrue);
      expect(m1 == m3, isTrue);
      expect(m1 <= m3, isTrue);
      expect(m1 >= m3, isTrue);
    });

    test('formats currency properly with Indian formatting', () {
      final positive = Money(285040);
      final negative = Money(-1520);

      expect(positive.format(), contains('2,850.40'));
      expect(positive.format(includeSign: true), contains('+'));
      expect(negative.format(), contains('-'));
    });

    test('Formatters percent formatting works', () {
      expect(Formatters.formatPercentage(0.36), equals('+0.36%'));
      expect(Formatters.formatPercentage(-1.25), equals('-1.25%'));
      expect(Formatters.formatPercentage(0.0), equals('0.00%'));
    });
  });
}
