import 'package:flutter_test/flutter_test.dart';
import 'package:trading_app/core/constants/stock_constants.dart';
import 'package:trading_app/core/money/money.dart';
import 'package:trading_app/data/local/local_storage_service.dart';
import 'package:trading_app/data/repositories/holding_repository_impl.dart';
import 'package:trading_app/data/repositories/order_repository_impl.dart';
import 'package:trading_app/data/repositories/wallet_repository_impl.dart';
import 'package:trading_app/data/repositories/watchlist_repository_impl.dart';
import 'package:trading_app/features/holdings/domain/entities/holding.dart';
import 'package:trading_app/features/trading/domain/entities/order.dart';
import 'package:trading_app/features/watchlist/domain/entities/watchlist.dart';


void main() {
  late LocalStorageService storageService;
  late WatchlistRepositoryImpl watchlistRepo;
  late WalletRepositoryImpl walletRepo;
  late HoldingRepositoryImpl holdingRepo;
  late OrderRepositoryImpl orderRepo;

  setUp(() {
    storageService = InMemoryLocalStorageService();
    watchlistRepo = WatchlistRepositoryImpl(storageService);
    walletRepo = WalletRepositoryImpl(storageService);
    holdingRepo = HoldingRepositoryImpl(storageService);
    orderRepo = OrderRepositoryImpl(storageService);
  });

  group('WatchlistRepository Tests', () {
    test('initializes default watchlists on fresh launch', () async {
      final watchlists = await watchlistRepo.getWatchlists();
      expect(watchlists, isNotEmpty);
      expect(watchlists.first.symbols, contains(StockConstants.reliance));
    });

    test('saves and retrieves modified watchlists', () async {
      const customWatchlist = Watchlist(
        id: 'wl_custom',
        name: 'My Tech Portfolio',
        symbols: [StockConstants.tcs, StockConstants.infy],
      );

      await watchlistRepo.saveWatchlists([customWatchlist]);
      final loaded = await watchlistRepo.getWatchlists();

      expect(loaded.length, equals(1));
      expect(loaded.first.name, equals('My Tech Portfolio'));
      expect(loaded.first.symbols, equals([StockConstants.tcs, StockConstants.infy]));
    });

    test('persists active watchlist id', () async {
      await watchlistRepo.saveActiveWatchlistId('wl_custom_2');
      final activeId = await watchlistRepo.getActiveWatchlistId();
      expect(activeId, equals('wl_custom_2'));
    });
  });

  group('WalletRepository Tests', () {
    test('initializes wallet with default ₹1,00,000 (10,000,000 paise)', () async {
      final wallet = await walletRepo.getWallet();
      expect(wallet.balance.paise, equals(10000000));
      expect(wallet.balance.toRupees, equals(100000.00));
    });

    test('persists updated wallet balance after trade deduction', () async {
      final current = await walletRepo.getWallet();
      final updated = current.deduct(const Money(285000)); // Buy 1 RELIANCE @ ₹2850

      await walletRepo.saveWallet(updated);
      final restored = await walletRepo.getWallet();

      expect(restored.balance.paise, equals(9715000));
      expect(restored.balance.toRupees, equals(97150.00));
    });
  });

  group('HoldingRepository Tests', () {
    test('saves and retrieves holdings by symbol', () async {
      final holding = Holding(
        symbol: StockConstants.reliance,
        quantity: 10,
        averageCost: const Money(270000), // ₹2700.00
        lastUpdated: DateTime.now(),
      );

      await holdingRepo.saveHolding(holding);
      final retrieved = await holdingRepo.getHoldingBySymbol(StockConstants.reliance);

      expect(retrieved, isNotNull);
      expect(retrieved!.quantity, equals(10));
      expect(retrieved.averageCost.paise, equals(270000));
      expect(retrieved.investedValue.paise, equals(2700000)); // ₹27,000.00
    });

    test('updates holding with weighted average cost on additional buy', () async {
      // Existing: 10 shares @ ₹2700
      final existing = Holding(
        symbol: StockConstants.reliance,
        quantity: 10,
        averageCost: const Money(270000),
        lastUpdated: DateTime.now(),
      );
      await holdingRepo.saveHolding(existing);

      // Buy additional 5 shares @ ₹2850
      // Total Qty = 15
      // Total Invested = (10 * 2700) + (5 * 2850) = 27000 + 14250 = 41250
      // Avg Cost = 41250 / 15 = 2750
      final updated = existing.addShares(5, const Money(285000));
      await holdingRepo.saveHolding(updated);

      final loaded = await holdingRepo.getHoldingBySymbol(StockConstants.reliance);
      expect(loaded!.quantity, equals(15));
      expect(loaded.averageCost.paise, equals(275000)); // ₹2750.00
      expect(loaded.investedValue.paise, equals(4125000)); // ₹41,250.00
    });

    test('removes holding when all shares sold', () async {
      final holding = Holding(
        symbol: StockConstants.tcs,
        quantity: 5,
        averageCost: const Money(390000),
        lastUpdated: DateTime.now(),
      );
      await holdingRepo.saveHolding(holding);

      // Sell all 5 shares
      final reduced = holding.reduceShares(5);
      expect(reduced, isNull);

      await holdingRepo.removeHolding(StockConstants.tcs);
      final loaded = await holdingRepo.getHoldingBySymbol(StockConstants.tcs);
      expect(loaded, isNull);
    });
  });

  group('OrderRepository Tests', () {
    test('saves and retrieves order history sorted newest first', () async {
      final order1 = Order(
        id: 'ord_1',
        symbol: StockConstants.reliance,
        side: OrderSide.buy,
        quantity: 10,
        price: const Money(285000),
        totalValue: const Money(2850000),
        timestamp: DateTime(2026, 8, 23, 10, 0),
      );

      final order2 = Order(
        id: 'ord_2',
        symbol: StockConstants.tcs,
        side: OrderSide.buy,
        quantity: 5,
        price: const Money(392000),
        totalValue: const Money(1960000),
        timestamp: DateTime(2026, 8, 23, 10, 30),
      );

      await orderRepo.saveOrder(order1);
      await orderRepo.saveOrder(order2);

      final orders = await orderRepo.getOrders();
      expect(orders.length, equals(2));
      expect(orders.first.id, equals('ord_2')); // Newest first
      expect(orders.last.id, equals('ord_1'));
    });
  });
}
