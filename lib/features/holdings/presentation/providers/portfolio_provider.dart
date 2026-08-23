import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/money/money.dart';
import '../../../market/presentation/providers/market_feed_provider.dart';
import '../../../trading/presentation/providers/wallet_provider.dart';
import '../../domain/entities/holding.dart';
import '../../domain/entities/portfolio_summary.dart';

enum HoldingSortOption {
  symbolAsc('Symbol (A-Z)'),
  valueDesc('Current Value (High to Low)'),
  pnlDesc('P&L % (Highest Gainers)'),
  pnlAsc('P&L % (Biggest Losers)'),
  quantityDesc('Quantity (High to Low)');

  final String label;
  const HoldingSortOption(this.label);
}

final holdingsSortOptionProvider =
    StateProvider<HoldingSortOption>((ref) => HoldingSortOption.pnlDesc);


/// Real-time aggregated Portfolio Summary computed continuously from live market ticks
final portfolioSummaryProvider = Provider<PortfolioSummary>((ref) {
  final walletAsync = ref.watch(walletProvider);
  final holdingsAsync = ref.watch(holdingsMapProvider);
  final priceStore = ref.watch(marketPriceStoreProvider);

  final cashBalance = walletAsync.value?.balance ?? const Money(10000000);
  final holdingsMap = holdingsAsync.value ?? {};

  if (holdingsMap.isEmpty) {
    return PortfolioSummary(
      totalPortfolioValue: cashBalance,
      totalInvested: Money.zero,
      totalCurrentValue: Money.zero,
      totalPnL: Money.zero,
      totalPnLPercentage: 0.0,
      totalDayPnL: Money.zero,
      totalDayPnLPercentage: 0.0,
      cashBalance: cashBalance,
      totalHoldingsCount: 0,
    );
  }

  int totalInvestedPaise = 0;
  int totalCurrentValuePaise = 0;
  int totalDayPnLPaise = 0;

  for (final holding in holdingsMap.values) {
    final tick = priceStore[holding.symbol];
    final currentLtp = tick?.currentPrice ?? holding.averageCost;
    final dayChange = tick?.change ?? Money.zero;

    final investedPaise = holding.investedValue.paise;
    final currentValPaise = currentLtp.paise * holding.quantity;
    final dayPnLPaise = dayChange.paise * holding.quantity;

    totalInvestedPaise += investedPaise;
    totalCurrentValuePaise += currentValPaise;
    totalDayPnLPaise += dayPnLPaise;
  }

  final totalInvested = Money(totalInvestedPaise);
  final totalCurrentValue = Money(totalCurrentValuePaise);
  final totalPnL = Money(totalCurrentValuePaise - totalInvestedPaise);
  final totalDayPnL = Money(totalDayPnLPaise);

  final double totalPnLPercentage = totalInvestedPaise > 0
      ? ((totalCurrentValuePaise - totalInvestedPaise) / totalInvestedPaise) * 100
      : 0.0;

  final double totalDayPnLPercentage = totalInvestedPaise > 0
      ? (totalDayPnLPaise / totalInvestedPaise) * 100
      : 0.0;

  final totalPortfolioValue = Money(totalCurrentValuePaise + cashBalance.paise);

  return PortfolioSummary(
    totalPortfolioValue: totalPortfolioValue,
    totalInvested: totalInvested,
    totalCurrentValue: totalCurrentValue,
    totalPnL: totalPnL,
    totalPnLPercentage: totalPnLPercentage,
    totalDayPnL: totalDayPnL,
    totalDayPnLPercentage: totalDayPnLPercentage,
    cashBalance: cashBalance,
    totalHoldingsCount: holdingsMap.length,
  );
});

/// List of holdings sorted according to the active sort option and live market values
final sortedHoldingsProvider = Provider<List<Holding>>((ref) {
  final holdingsAsync = ref.watch(holdingsMapProvider);
  final sortOption = ref.watch(holdingsSortOptionProvider);
  final priceStore = ref.watch(marketPriceStoreProvider);

  final holdings = (holdingsAsync.value ?? {}).values.toList();
  if (holdings.isEmpty) return [];

  final sorted = List<Holding>.from(holdings);

  switch (sortOption) {
    case HoldingSortOption.symbolAsc:
      sorted.sort((a, b) => a.symbol.compareTo(b.symbol));
      break;
    case HoldingSortOption.quantityDesc:
      sorted.sort((a, b) => b.quantity.compareTo(a.quantity));
      break;
    case HoldingSortOption.valueDesc:
      sorted.sort((a, b) {
        final ltpA = priceStore[a.symbol]?.currentPrice ?? a.averageCost;
        final ltpB = priceStore[b.symbol]?.currentPrice ?? b.averageCost;
        final valA = ltpA.paise * a.quantity;
        final valB = ltpB.paise * b.quantity;
        return valB.compareTo(valA);
      });
      break;
    case HoldingSortOption.pnlDesc:
      sorted.sort((a, b) {
        final ltpA = priceStore[a.symbol]?.currentPrice ?? a.averageCost;
        final ltpB = priceStore[b.symbol]?.currentPrice ?? b.averageCost;
        final pnlA = (ltpA.paise - a.averageCost.paise) / a.averageCost.paise;
        final pnlB = (ltpB.paise - b.averageCost.paise) / b.averageCost.paise;
        return pnlB.compareTo(pnlA);
      });
      break;
    case HoldingSortOption.pnlAsc:
      sorted.sort((a, b) {
        final ltpA = priceStore[a.symbol]?.currentPrice ?? a.averageCost;
        final ltpB = priceStore[b.symbol]?.currentPrice ?? b.averageCost;
        final pnlA = (ltpA.paise - a.averageCost.paise) / a.averageCost.paise;
        final pnlB = (ltpB.paise - b.averageCost.paise) / b.averageCost.paise;
        return pnlA.compareTo(pnlB);
      });
      break;
  }

  return sorted;
});
