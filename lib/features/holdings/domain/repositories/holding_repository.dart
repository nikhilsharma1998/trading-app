import '../entities/holding.dart';

abstract class HoldingRepository {
  /// Returns map of all user holdings keyed by stock symbol
  Future<Map<String, Holding>> getHoldings();

  /// Gets holding for a single stock symbol
  Future<Holding?> getHoldingBySymbol(String symbol);

  /// Saves or updates a holding
  Future<void> saveHolding(Holding holding);

  /// Removes a holding when quantity reaches zero
  Future<void> removeHolding(String symbol);

  /// Saves the complete map of holdings
  Future<void> saveAllHoldings(Map<String, Holding> holdings);
}
