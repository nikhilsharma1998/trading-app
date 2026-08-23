import '../money/money.dart';

/// Centralized constants for the 10 mandatory stocks and reference prices.
class StockConstants {
  StockConstants._();

  static const String reliance = 'RELIANCE';
  static const String tcs = 'TCS';
  static const String infy = 'INFY';
  static const String hdfcBank = 'HDFCBANK';
  static const String iciciBank = 'ICICIBANK';
  static const String sbin = 'SBIN';
  static const String itc = 'ITC';
  static const String lt = 'LT';
  static const String bhartiAirtel = 'BHARTIARTL';
  static const String axisBank = 'AXISBANK';

  /// List of exactly 10 mandatory stock symbols supported by the application.
  static const List<String> allSymbols = [
    reliance,
    tcs,
    infy,
    hdfcBank,
    iciciBank,
    sbin,
    itc,
    lt,
    bhartiAirtel,
    axisBank,
  ];

  /// Company full names mapping
  static const Map<String, String> companyNames = {
    reliance: 'Reliance Industries Ltd.',
    tcs: 'Tata Consultancy Services Ltd.',
    infy: 'Infosys Ltd.',
    hdfcBank: 'HDFC Bank Ltd.',
    iciciBank: 'ICICI Bank Ltd.',
    sbin: 'State Bank of India',
    itc: 'ITC Ltd.',
    lt: 'Larsen & Toubro Ltd.',
    bhartiAirtel: 'Bharti Airtel Ltd.',
    axisBank: 'Axis Bank Ltd.',
  };

  /// Initial reference prices in paise
  static const Map<String, Money> startingPrices = {
    reliance: Money(285000), // ₹2850.00
    tcs: Money(392000),      // ₹3920.00
    infy: Money(174000),     // ₹1740.00
    hdfcBank: Money(198000), // ₹1980.00
    iciciBank: Money(142000),// ₹1420.00
    sbin: Money(81000),      // ₹810.00
    itc: Money(42000),       // ₹420.00
    lt: Money(365000),       // ₹3650.00
    bhartiAirtel: Money(185000), // ₹1850.00
    axisBank: Money(125000), // ₹1250.00
  };

  /// Default initial wallet balance: ₹1,00,000 (10,000,000 paise)
  static const Money initialWalletBalance = Money(10000000);
}
