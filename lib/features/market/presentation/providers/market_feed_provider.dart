import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/stock_constants.dart';
import '../../../../core/money/money.dart';
import '../../../../data/repositories/market_repository_impl.dart';
import '../../data/models/market_tick.dart';
import '../../data/services/mock_market_feed.dart';
import '../../domain/entities/stock.dart';
import '../../domain/repositories/market_repository.dart';

/// Central singleton MockMarketFeed instance
final mockMarketFeedProvider = Provider<MockMarketFeed>((ref) {
  final feed = MockMarketFeed();
  feed.start();
  ref.onDispose(() => feed.dispose());
  return feed;
});

/// Market repository provider
final marketRepositoryProvider = Provider<MarketRepository>((ref) {
  final feed = ref.watch(mockMarketFeedProvider);
  return MarketRepositoryImpl(feed);
});

/// StateNotifier for controlling market feed speed (Normal vs Stress 50+ ticks/sec)
class MarketFeedSpeedNotifier extends StateNotifier<MarketFeedSpeed> {
  final MarketRepository _repository;

  MarketFeedSpeedNotifier(this._repository) : super(_repository.currentSpeed);

  void setSpeed(MarketFeedSpeed speed) {
    _repository.setFeedSpeed(speed);
    state = speed;
  }

  void toggleSpeed() {
    if (state == MarketFeedSpeed.normal) {
      setSpeed(MarketFeedSpeed.stress);
    } else {
      setSpeed(MarketFeedSpeed.normal);
    }
  }
}

final marketFeedSpeedProvider =
    StateNotifierProvider<MarketFeedSpeedNotifier, MarketFeedSpeed>((ref) {
  final repository = ref.watch(marketRepositoryProvider);
  return MarketFeedSpeedNotifier(repository);
});

/// StateNotifier managing the live price store (Map of all latest stock ticks)
class MarketPriceStoreNotifier extends StateNotifier<Map<String, MarketTick>> {
  final MarketRepository _repository;

  MarketPriceStoreNotifier(this._repository)
      : super(_repository.getAllLatestTicks()) {
    _subscribeToTicks();
  }

  void _subscribeToTicks() {
    _repository.tickStream.listen((tick) {
      state = {
        ...state,
        tick.symbol: tick,
      };
    });
  }

  /// Forces an update for testing
  void forceTick(String symbol) {
    state = _repository.getAllLatestTicks();
  }
}

/// Central price store provider exposing all 10 stock ticks
final marketPriceStoreProvider =
    StateNotifierProvider<MarketPriceStoreNotifier, Map<String, MarketTick>>((ref) {
  final repository = ref.watch(marketRepositoryProvider);
  return MarketPriceStoreNotifier(repository);
});

/// Granular Family Provider for a single stock's latest MarketTick.
/// Only widgets subscribed to this symbol will rebuild on tick.
final stockTickProvider = Provider.family<MarketTick, String>((ref, symbol) {
  final store = ref.watch(marketPriceStoreProvider);
  return store[symbol] ??
      MarketTick.initial(
        symbol: symbol,
        initialPrice: StockConstants.startingPrices[symbol] ?? const Money(100000),
      );
});

/// Granular Family Provider for a single stock's live LTP Money.
final stockPriceProvider = Provider.family<Money, String>((ref, symbol) {
  final tick = ref.watch(stockTickProvider(symbol));
  return tick.currentPrice;
});

/// Provider returning list of all 10 Stock entities with current metadata
final allStocksProvider = Provider<List<Stock>>((ref) {
  final repository = ref.watch(marketRepositoryProvider);
  ref.watch(marketPriceStoreProvider); // Re-evaluate when ticks update
  return repository.getAllStocks();
});
