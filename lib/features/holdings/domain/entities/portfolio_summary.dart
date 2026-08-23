import '../../../../core/money/money.dart';

/// Immutable value object containing real-time aggregated portfolio statistics
class PortfolioSummary {
  final Money totalPortfolioValue; // Current Value of Holdings + Cash Balance
  final Money totalInvested;       // Sum of (Quantity * Avg Price) for all holdings
  final Money totalCurrentValue;   // Sum of (Quantity * Live LTP) for all holdings
  final Money totalPnL;            // Total Current Value - Total Invested
  final double totalPnLPercentage; // (Total PnL / Total Invested) * 100
  final Money totalDayPnL;         // Sum of (Day Change * Quantity)
  final double totalDayPnLPercentage;
  final Money cashBalance;         // Available Wallet cash
  final int totalHoldingsCount;

  const PortfolioSummary({
    required this.totalPortfolioValue,
    required this.totalInvested,
    required this.totalCurrentValue,
    required this.totalPnL,
    required this.totalPnLPercentage,
    required this.totalDayPnL,
    required this.totalDayPnLPercentage,
    required this.cashBalance,
    required this.totalHoldingsCount,
  });

  static const PortfolioSummary empty = PortfolioSummary(
    totalPortfolioValue: Money(10000000), // Default ₹1,00,000 cash
    totalInvested: Money.zero,
    totalCurrentValue: Money.zero,
    totalPnL: Money.zero,
    totalPnLPercentage: 0.0,
    totalDayPnL: Money.zero,
    totalDayPnLPercentage: 0.0,
    cashBalance: Money(10000000),
    totalHoldingsCount: 0,
  );
}
