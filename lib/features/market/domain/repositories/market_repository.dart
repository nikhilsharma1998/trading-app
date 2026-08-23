import '../../../../core/money/money.dart';
import '../../data/models/market_tick.dart';
import '../entities/stock.dart';

enum MarketFeedSpeed {
  normal(1000, 'Normal (1 tick/sec)'), // 1 tick/sec per stock = 1000ms / 10 = 100ms per round-robin tick
  stress(200, 'Stress (5 ticks/sec)'), // 5 ticks/sec per stock = 200ms / 10 = 20ms per round-robin tick
  fast(500, 'Fast (2 ticks/sec)'),
  paused(0, 'Paused');

  final int intervalMs;
  final String label;
  const MarketFeedSpeed(this.intervalMs, this.label);
}

abstract class MarketRepository {
  /// Stream of all market ticks across all stocks
  Stream<MarketTick> get tickStream;

  /// Stream of ticks filtered for a single stock
  Stream<MarketTick> getStockTickStream(String symbol);

  /// Returns current in-memory snapshot of all latest ticks
  Map<String, MarketTick> getAllLatestTicks();

  /// Gets immediate latest tick for a symbol
  MarketTick? getLatestTick(String symbol);

  /// Gets immediate latest LTP price for order execution (atomic price query)
  Money getLatestPrice(String symbol);

  /// Returns list of all 10 stocks with metadata and latest ticks
  List<Stock> getAllStocks();

  /// Updates feed tick rate
  void setFeedSpeed(MarketFeedSpeed speed);

  /// Current feed speed
  MarketFeedSpeed get currentSpeed;

  /// Start the continuous feed engine
  void startFeed();

  /// Stop or pause the feed engine
  void stopFeed();
}
