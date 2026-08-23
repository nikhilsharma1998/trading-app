import 'dart:async';
import '../../../../core/constants/stock_constants.dart';
import '../../../../core/money/money.dart';
import '../../../../core/utils/tick_generator.dart';
import '../../domain/repositories/market_repository.dart';
import '../models/market_tick.dart';

/// Centralized Mock Market Feed Engine.
/// Single source of truth for stock market prices throughout the entire application.
class MockMarketFeed {
  final TickGenerator _generator;
  final StreamController<MarketTick> _tickStreamController =
      StreamController<MarketTick>.broadcast();

  final Map<String, MarketTick> _priceStore = {};
  Timer? _timer;
  int _currentStockIndex = 0;
  MarketFeedSpeed _speed = MarketFeedSpeed.normal;

  MockMarketFeed({TickGenerator? generator})
      : _generator = generator ?? TickGenerator() {
    _initializeInitialPrices();
  }

  /// Initialize all 10 stocks with their starting reference prices
  void _initializeInitialPrices() {
    for (final symbol in StockConstants.allSymbols) {
      final initialPrice =
          StockConstants.startingPrices[symbol] ?? const Money(100000);
      _priceStore[symbol] = MarketTick.initial(
        symbol: symbol,
        initialPrice: initialPrice,
      );
    }
  }

  Stream<MarketTick> get tickStream => _tickStreamController.stream;

  Map<String, MarketTick> get priceStore => Map.unmodifiable(_priceStore);

  MarketFeedSpeed get speed => _speed;

  MarketTick? getLatestTick(String symbol) => _priceStore[symbol];

  Money getLatestPrice(String symbol) {
    return _priceStore[symbol]?.currentPrice ??
        StockConstants.startingPrices[symbol] ??
        const Money(100000);
  }

  /// Starts or restarts the continuous mock feed timer
  void start({MarketFeedSpeed? speed}) {
    if (speed != null) _speed = speed;
    _timer?.cancel();

    if (_speed == MarketFeedSpeed.paused) return;

    // Distribute ticks round-robin across the 10 stocks.
    // E.g., Normal mode (1000ms / 10 stocks = 100ms per tick).
    // Stress mode (200ms / 10 stocks = 20ms per tick = 50 ticks/sec).
    final timerIntervalMs = (_speed.intervalMs / StockConstants.allSymbols.length).round();

    _timer = Timer.periodic(Duration(milliseconds: timerIntervalMs), (timer) {
      _tickNextStock();
    });
  }

  /// Changes the feed speed dynamically
  void setSpeed(MarketFeedSpeed speed) {
    _speed = speed;
    start();
  }

  /// Emits a single tick for the next stock in round-robin sequence
  void _tickNextStock() {
    if (_priceStore.isEmpty) return;

    final symbols = StockConstants.allSymbols;
    final symbol = symbols[_currentStockIndex % symbols.length];
    _currentStockIndex = (_currentStockIndex + 1) % symbols.length;

    tickStock(symbol);
  }

  /// Forces a tick update for a specific stock (useful for tests and simulation)
  MarketTick tickStock(String symbol) {
    final currentTick = _priceStore[symbol] ??
        MarketTick.initial(
          symbol: symbol,
          initialPrice: StockConstants.startingPrices[symbol] ?? const Money(100000),
        );

    final basePrice = StockConstants.startingPrices[symbol] ?? const Money(100000);
    final nextPrice = _generator.generateNextPrice(
      currentPrice: currentTick.currentPrice,
      basePrice: basePrice,
    );

    final newTick = currentTick.nextTick(nextPrice);
    _priceStore[symbol] = newTick;

    if (!_tickStreamController.isClosed) {
      _tickStreamController.add(newTick);
    }

    return newTick;
  }

  /// Forces a tick update for all 10 stocks simultaneously
  void tickAll() {
    for (final symbol in StockConstants.allSymbols) {
      tickStock(symbol);
    }
  }

  /// Pauses the market feed
  void pause() {
    _timer?.cancel();
    _timer = null;
    _speed = MarketFeedSpeed.paused;
  }

  /// Disposes resources
  void dispose() {
    _timer?.cancel();
    _tickStreamController.close();
  }
}
