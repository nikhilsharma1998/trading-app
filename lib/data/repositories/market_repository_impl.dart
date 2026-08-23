import '../../core/constants/stock_constants.dart';
import '../../core/money/money.dart';
import '../../features/market/data/models/market_tick.dart';
import '../../features/market/data/services/mock_market_feed.dart';
import '../../features/market/domain/entities/stock.dart';
import '../../features/market/domain/repositories/market_repository.dart';

class MarketRepositoryImpl implements MarketRepository {
  final MockMarketFeed _feed;

  MarketRepositoryImpl(this._feed);

  @override
  Stream<MarketTick> get tickStream => _feed.tickStream;

  @override
  Stream<MarketTick> getStockTickStream(String symbol) {
    return _feed.tickStream.where((tick) => tick.symbol == symbol);
  }

  @override
  Map<String, MarketTick> getAllLatestTicks() => _feed.priceStore;

  @override
  MarketTick? getLatestTick(String symbol) => _feed.getLatestTick(symbol);

  @override
  Money getLatestPrice(String symbol) => _feed.getLatestPrice(symbol);

  @override
  List<Stock> getAllStocks() {
    return StockConstants.allSymbols.map((symbol) {
      final name = StockConstants.companyNames[symbol] ?? symbol;
      final initialPrice = StockConstants.startingPrices[symbol] ?? const Money(100000);
      final tick = _feed.getLatestTick(symbol);
      return Stock(
        symbol: symbol,
        name: name,
        initialPrice: initialPrice,
        latestTick: tick,
      );
    }).toList();
  }

  @override
  void setFeedSpeed(MarketFeedSpeed speed) {
    _feed.setSpeed(speed);
  }

  @override
  MarketFeedSpeed get currentSpeed => _feed.speed;

  @override
  void startFeed() {
    _feed.start();
  }

  @override
  void stopFeed() {
    _feed.pause();
  }
}
