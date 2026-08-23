import '../../../../core/money/money.dart';

/// Immutable domain entity representing a portfolio holding
class Holding {
  final String symbol;
  final int quantity;
  final Money averageCost;
  final DateTime lastUpdated;

  const Holding({
    required this.symbol,
    required this.quantity,
    required this.averageCost,
    required this.lastUpdated,
  });

  /// Total capital invested in this stock (Quantity * Average Cost)
  Money get investedValue => averageCost * quantity;

  /// Calculates current value at live LTP (Quantity * Current LTP)
  Money calculateCurrentValue(Money currentLtp) => currentLtp * quantity;

  /// Calculates live P&L in Rupees (Current Value - Invested Value)
  Money calculatePnl(Money currentLtp) => calculateCurrentValue(currentLtp) - investedValue;

  /// Calculates live P&L percentage ((P&L / Invested Value) * 100)
  double calculatePnlPercentage(Money currentLtp) {
    if (investedValue.paise == 0) return 0.0;
    final pnlPaise = calculatePnl(currentLtp).paise;
    return (pnlPaise / investedValue.paise) * 100.0;
  }

  /// Computes new weighted average cost when additional shares are bought
  Holding addShares(int additionalQty, Money executionPrice) {
    if (additionalQty <= 0) return this;
    final newTotalQty = quantity + additionalQty;
    final currentInvestedPaise = quantity * averageCost.paise;
    final additionalInvestedPaise = additionalQty * executionPrice.paise;
    final newTotalInvestedPaise = currentInvestedPaise + additionalInvestedPaise;
    final newAvgCostPaise = (newTotalInvestedPaise / newTotalQty).round();

    return Holding(
      symbol: symbol,
      quantity: newTotalQty,
      averageCost: Money(newAvgCostPaise),
      lastUpdated: DateTime.now(),
    );
  }

  /// Reduces holding quantity when shares are sold.
  /// Returns null if all shares are sold (quantity becomes 0).
  Holding? reduceShares(int sellQty) {
    if (sellQty <= 0) return this;
    if (sellQty >= quantity) return null; // Removed from portfolio
    return Holding(
      symbol: symbol,
      quantity: quantity - sellQty,
      averageCost: averageCost, // Average cost remains unchanged on sell
      lastUpdated: DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Holding &&
          runtimeType == other.runtimeType &&
          symbol == other.symbol &&
          quantity == other.quantity &&
          averageCost == other.averageCost;

  @override
  int get hashCode =>
      symbol.hashCode ^ quantity.hashCode ^ averageCost.hashCode;
}
