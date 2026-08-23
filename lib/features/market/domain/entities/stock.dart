import '../../../../core/money/money.dart';
import '../../data/models/market_tick.dart';

/// Domain entity representing a stock instrument with its company details
class Stock {
  final String symbol;
  final String name;
  final Money initialPrice;
  final MarketTick? latestTick;

  const Stock({
    required this.symbol,
    required this.name,
    required this.initialPrice,
    this.latestTick,
  });

  Stock copyWith({
    String? symbol,
    String? name,
    Money? initialPrice,
    MarketTick? latestTick,
  }) {
    return Stock(
      symbol: symbol ?? this.symbol,
      name: name ?? this.name,
      initialPrice: initialPrice ?? this.initialPrice,
      latestTick: latestTick ?? this.latestTick,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Stock &&
          runtimeType == other.runtimeType &&
          symbol == other.symbol &&
          name == other.name &&
          initialPrice == other.initialPrice &&
          latestTick == other.latestTick;

  @override
  int get hashCode =>
      symbol.hashCode ^ name.hashCode ^ initialPrice.hashCode ^ latestTick.hashCode;
}
