import '../../../../core/money/money.dart';

/// Represents user's trading cash balance
class Wallet {
  final Money balance;

  const Wallet({required this.balance});

  Wallet copyWith({Money? balance}) {
    return Wallet(balance: balance ?? this.balance);
  }

  bool canAfford(Money amount) => balance >= amount;

  Wallet deduct(Money amount) {
    if (!canAfford(amount)) {
      throw ArgumentError('Insufficient funds to deduct ${amount.format()}');
    }
    return Wallet(balance: balance - amount);
  }

  Wallet add(Money amount) {
    return Wallet(balance: balance + amount);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Wallet &&
          runtimeType == other.runtimeType &&
          balance == other.balance;

  @override
  int get hashCode => balance.hashCode;
}
