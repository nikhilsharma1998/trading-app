import '../../../../core/money/money.dart';

enum PriceDirection {
  up,
  down,
  unchanged;

  bool get isUp => this == PriceDirection.up;
  bool get isDown => this == PriceDirection.down;
}

/// Represents an immutable market price tick emitted by the mock market feed
class MarketTick {
  final String symbol;
  final Money currentPrice;
  final Money previousPrice;
  final Money dayOpenPrice;
  final Money change;
  final double changePercentage;
  final DateTime timestamp;
  final PriceDirection direction;

  const MarketTick({
    required this.symbol,
    required this.currentPrice,
    required this.previousPrice,
    required this.dayOpenPrice,
    required this.change,
    required this.changePercentage,
    required this.timestamp,
    required this.direction,
  });

  /// Factory to initialize a starting tick from baseline stock price
  factory MarketTick.initial({
    required String symbol,
    required Money initialPrice,
  }) {
    return MarketTick(
      symbol: symbol,
      currentPrice: initialPrice,
      previousPrice: initialPrice,
      dayOpenPrice: initialPrice,
      change: Money.zero,
      changePercentage: 0.0,
      timestamp: DateTime.now(),
      direction: PriceDirection.unchanged,
    );
  }

  /// Creates a new tick given a new price
  MarketTick nextTick(Money newPrice) {
    PriceDirection dir;
    if (newPrice.paise > currentPrice.paise) {
      dir = PriceDirection.up;
    } else if (newPrice.paise < currentPrice.paise) {
      dir = PriceDirection.down;
    } else {
      dir = PriceDirection.unchanged;
    }

    final priceChange = newPrice - dayOpenPrice;
    final changePct = dayOpenPrice.paise > 0
        ? (priceChange.paise / dayOpenPrice.paise) * 100.0
        : 0.0;

    return MarketTick(
      symbol: symbol,
      currentPrice: newPrice,
      previousPrice: currentPrice,
      dayOpenPrice: dayOpenPrice,
      change: priceChange,
      changePercentage: changePct,
      timestamp: DateTime.now(),
      direction: dir,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MarketTick &&
          runtimeType == other.runtimeType &&
          symbol == other.symbol &&
          currentPrice == other.currentPrice &&
          previousPrice == other.previousPrice &&
          dayOpenPrice == other.dayOpenPrice &&
          change == other.change &&
          direction == other.direction;

  @override
  int get hashCode =>
      symbol.hashCode ^
      currentPrice.hashCode ^
      previousPrice.hashCode ^
      dayOpenPrice.hashCode ^
      change.hashCode ^
      direction.hashCode;
}
