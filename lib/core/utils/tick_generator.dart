import 'dart:math';
import '../money/money.dart';

/// Generates realistic bounded random-walk price movements for market simulation.
class TickGenerator {
  final Random _random;

  TickGenerator([Random? random]) : _random = random ?? Random();

  /// Generates the next price for a stock based on its current price and reference base price.
  /// Fluctuation per tick is kept realistically between -0.30% and +0.30%.
  /// Total fluctuation is bounded within ±12% of the reference starting price.
  Money generateNextPrice({
    required Money currentPrice,
    required Money basePrice,
  }) {
    // Percentage fluctuation between -0.30% (-0.0030) and +0.30% (+0.0030)
    // with slight mean-reverting pull towards base price if it deviates beyond 8%
    final deviationFromBase = (currentPrice.paise - basePrice.paise) / basePrice.paise;

    double meanReversion = 0.0;
    if (deviationFromBase > 0.08) {
      meanReversion = -0.0010; // Pull down
    } else if (deviationFromBase < -0.08) {
      meanReversion = 0.0010;  // Pull up
    }

    // Random percentage change: -0.25% to +0.25%
    final randomDelta = (_random.nextDouble() * 0.0050) - 0.0025;
    final totalDeltaFactor = randomDelta + meanReversion;

    // Calculate delta paise, ensuring at least ±5 paise movement unless random hits exactly 0
    int deltaPaise = (currentPrice.paise * totalDeltaFactor).round();
    if (deltaPaise == 0) {
      deltaPaise = _random.nextBool() ? 5 : -5;
    }

    int nextPaise = currentPrice.paise + deltaPaise;

    // Hard bounds: ±15% of base price, min ₹1.00 (100 paise)
    final minPaise = (basePrice.paise * 0.85).round().clamp(100, double.maxFinite.toInt());
    final maxPaise = (basePrice.paise * 1.15).round();

    nextPaise = nextPaise.clamp(minPaise, maxPaise);

    return Money(nextPaise);
  }
}
