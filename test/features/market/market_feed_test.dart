import 'package:flutter_test/flutter_test.dart';
import 'package:trading_app/core/constants/stock_constants.dart';
import 'package:trading_app/core/money/money.dart';
import 'package:trading_app/data/repositories/market_repository_impl.dart';
import 'package:trading_app/features/market/data/models/market_tick.dart';
import 'package:trading_app/features/market/data/services/mock_market_feed.dart';
import 'package:trading_app/features/market/domain/repositories/market_repository.dart';

void main() {
  late MockMarketFeed feed;
  late MarketRepositoryImpl marketRepo;

  setUp(() {
    feed = MockMarketFeed();
    marketRepo = MarketRepositoryImpl(feed);
  });

  tearDown(() {
    feed.dispose();
  });

  group('MockMarketFeed Tests', () {
    test('initializes all 10 stocks with correct starting prices', () {
      expect(feed.priceStore.length, equals(10));

      for (final symbol in StockConstants.allSymbols) {
        final tick = feed.getLatestTick(symbol);
        expect(tick, isNotNull);
        expect(tick!.symbol, equals(symbol));
        expect(tick.currentPrice, equals(StockConstants.startingPrices[symbol]));
        expect(tick.previousPrice, equals(StockConstants.startingPrices[symbol]));
        expect(tick.dayOpenPrice, equals(StockConstants.startingPrices[symbol]));
        expect(tick.change, equals(Money.zero));
        expect(tick.changePercentage, equals(0.0));
      }
    });

    test('generates realistic bounded price tick on tickStock()', () {
      final initialReliance = feed.getLatestTick(StockConstants.reliance)!;
      final initialPaise = initialReliance.currentPrice.paise;

      final updatedTick = feed.tickStock(StockConstants.reliance);

      expect(updatedTick.symbol, equals(StockConstants.reliance));
      expect(updatedTick.previousPrice.paise, equals(initialPaise));
      expect(updatedTick.currentPrice.paise, isNot(equals(0)));

      // Check that price change is bounded reasonably
      final diff = (updatedTick.currentPrice.paise - initialPaise).abs();
      expect(diff, lessThan((initialPaise * 0.05).round())); // less than 5% single tick movement


      // Direction should match price delta
      if (updatedTick.currentPrice.paise > initialPaise) {
        expect(updatedTick.direction, equals(PriceDirection.up));
      } else if (updatedTick.currentPrice.paise < initialPaise) {
        expect(updatedTick.direction, equals(PriceDirection.down));
      } else {
        expect(updatedTick.direction, equals(PriceDirection.unchanged));
      }
    });

    test('emits ticks to tickStream', () async {
      expectLater(
        feed.tickStream,
        emits(predicate<MarketTick>((tick) => tick.symbol == StockConstants.tcs)),
      );

      feed.tickStock(StockConstants.tcs);
    });

    test('switches speed between Normal and Stress modes', () {
      feed.setSpeed(MarketFeedSpeed.stress);
      expect(feed.speed, equals(MarketFeedSpeed.stress));

      feed.setSpeed(MarketFeedSpeed.normal);
      expect(feed.speed, equals(MarketFeedSpeed.normal));
    });
  });

  group('MarketRepository Tests', () {
    test('returns immediate latest price for stock', () {
      final reliancePrice = marketRepo.getLatestPrice(StockConstants.reliance);
      expect(reliancePrice, equals(const Money(285000)));

      feed.tickStock(StockConstants.reliance);
      final updatedPrice = marketRepo.getLatestPrice(StockConstants.reliance);
      expect(updatedPrice.paise, isPositive);
    });

    test('filters stream per stock symbol', () async {
      final infyStream = marketRepo.getStockTickStream(StockConstants.infy);

      expectLater(
        infyStream,
        emits(predicate<MarketTick>((tick) => tick.symbol == StockConstants.infy)),
      );

      // Emitting other stocks should not trigger infyStream
      feed.tickStock(StockConstants.reliance);
      feed.tickStock(StockConstants.infy);
    });

    test('getAllStocks returns all 10 stocks with accurate company names', () {
      final stocks = marketRepo.getAllStocks();
      expect(stocks.length, equals(10));
      expect(stocks.any((s) => s.symbol == StockConstants.reliance && s.name.contains('Reliance')), isTrue);
      expect(stocks.any((s) => s.symbol == StockConstants.tcs && s.name.contains('Tata Consultancy')), isTrue);
    });
  });
}
