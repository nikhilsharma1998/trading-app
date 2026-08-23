import 'package:intl/intl.dart';

/// Immutable Value Object representing monetary values in integer minor units (paise).
/// 1 Rupee = 100 Paise.
/// Avoids floating-point arithmetic errors in financial calculations.
class Money implements Comparable<Money> {
  final int paise;

  const Money(this.paise);

  static const Money zero = Money(0);

  /// Creates a Money instance from Rupees (e.g. 2850.35 -> 285035 paise)
  factory Money.fromRupees(double rupees) {
    return Money((rupees * 100).round());
  }

  /// Creates a Money instance from Paise
  factory Money.fromPaise(int paise) => Money(paise);

  /// Returns value in Rupees as double (for UI calculations/display if needed)
  double get toRupees => paise / 100.0;

  /// Returns whole rupees portion
  int get rupees => paise ~/ 100;

  /// Returns remaining paise portion (0..99)
  int get remainingPaise => (paise.abs()) % 100;

  bool get isNegative => paise < 0;
  bool get isZero => paise == 0;
  bool get isPositive => paise > 0;

  Money operator +(Money other) => Money(paise + other.paise);

  Money operator -(Money other) => Money(paise - other.paise);

  /// Multiplies money by a quantity or factor, rounding to nearest paise.
  Money operator *(num factor) => Money((paise * factor).round());

  /// Integer division
  Money dividedBy(int divisor) {
    if (divisor == 0) throw ArgumentError('Cannot divide money by zero');
    return Money(paise ~/ divisor);
  }

  Money abs() => Money(paise.abs());

  bool operator >(Money other) => paise > other.paise;
  bool operator >=(Money other) => paise >= other.paise;
  bool operator <(Money other) => paise < other.paise;
  bool operator <=(Money other) => paise <= other.paise;

  @override
  int compareTo(Money other) => paise.compareTo(other.paise);

  /// Formats the money into standard currency representation (e.g., ₹2,850.35 or -₹15.20)
  String format({bool includeSign = false, bool includeSymbol = true}) {
    final absRupees = paise.abs() / 100.0;
    final formatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: includeSymbol ? '₹' : '',
      decimalDigits: 2,
    );
    final formatted = formatter.format(absRupees);

    if (paise < 0) {
      return '-$formatted';
    } else if (paise > 0 && includeSign) {
      return '+$formatted';
    }
    return formatted;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Money && runtimeType == other.runtimeType && paise == other.paise;

  @override
  int get hashCode => paise.hashCode;

  @override
  String toString() => format();
}

