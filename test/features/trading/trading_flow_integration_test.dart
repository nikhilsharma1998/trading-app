import 'package:flutter_test/flutter_test.dart';
import 'package:trading_app/core/constants/stock_constants.dart';
import 'package:trading_app/core/money/money.dart';
import 'package:trading_app/data/local/local_storage_service.dart';
import 'package:trading_app/data/repositories/holding_repository_impl.dart';
import 'package:trading_app/data/repositories/market_repository_impl.dart';
import 'package:trading_app/data/repositories/order_repository_impl.dart';
import 'package:trading_app/data/repositories/wallet_repository_impl.dart';
import 'package:trading_app/features/market/data/services/mock_market_feed.dart';

import 'package:trading_app/features/trading/domain/entities/order.dart';
import 'package:trading_app/features/trading/domain/services/trading_service.dart';

void main() {
  late LocalStorageService storageService;
  late MockMarketFeed feed;
  late MarketRepositoryImpl marketRepo;
  late WalletRepositoryImpl walletRepo;
  late HoldingRepositoryImpl holdingRepo;
  late OrderRepositoryImpl orderRepo;
  late TradingService tradingService;

  setUp(() {
    storageService = InMemoryLocalStorageService();
    feed = MockMarketFeed();
    marketRepo = MarketRepositoryImpl(feed);
    walletRepo = WalletRepositoryImpl(storageService);
    holdingRepo = HoldingRepositoryImpl(storageService);
    orderRepo = OrderRepositoryImpl(storageService);

    tradingService = TradingService(
      marketRepository: marketRepo,
      walletRepository: walletRepo,
      holdingRepository: holdingRepo,
      orderRepository: orderRepo,
    );
  });

  tearDown(() {
    feed.dispose();
  });

  group('End-to-End Trading Lifecycle Integration Tests', () {
    test('complete multi-step buy, weighted average, sell and profit realization lifecycle', () async {
      // 1. Initial State: Wallet has ₹1,00,000, 0 Holdings, 0 Orders
      var wallet = await walletRepo.getWallet();
      expect(wallet.balance, equals(const Money(10000000))); // ₹1,00,000.00
      var holdings = await holdingRepo.getHoldings();
      expect(holdings.isEmpty, isTrue);
      var orders = await orderRepo.getOrders();
      expect(orders.isEmpty, isTrue);

      // 2. Buy 10 RELIANCE @ initial price ₹2,850.00 (Total ₹28,500.00)
      final buyResult1 = await tradingService.executeTrade(
        symbol: StockConstants.reliance,
        side: OrderSide.buy,
        quantity: 10,
      );

      expect(buyResult1.order.price, equals(const Money(285000)));
      expect(buyResult1.remainingBalance, equals(const Money(7150000))); // ₹71,500.00
      expect(buyResult1.remainingHoldingQty, equals(10));

      // Verify Holding
      var holding = await holdingRepo.getHoldingBySymbol(StockConstants.reliance);
      expect(holding, isNotNull);
      expect(holding!.quantity, equals(10));
      expect(holding.averageCost, equals(const Money(285000)));
      expect(holding.investedValue, equals(const Money(2850000)));

      // 3. Buy an additional 10 RELIANCE @ ₹2,850.00 (Total 20 shares, Invested ₹57,000.00)
      final buyResult2 = await tradingService.executeTrade(
        symbol: StockConstants.reliance,
        side: OrderSide.buy,
        quantity: 10,
      );

      expect(buyResult2.remainingBalance, equals(const Money(4300000))); // ₹43,000.00
      expect(buyResult2.remainingHoldingQty, equals(20));

      holding = await holdingRepo.getHoldingBySymbol(StockConstants.reliance);
      expect(holding!.quantity, equals(20));
      expect(holding.averageCost, equals(const Money(285000)));
      expect(holding.investedValue, equals(const Money(5700000)));

      // 4. Sell 5 shares of RELIANCE @ ₹2,850.00 (+₹14,250.00 returned to wallet)
      final sellResult1 = await tradingService.executeTrade(
        symbol: StockConstants.reliance,
        side: OrderSide.sell,
        quantity: 5,
      );

      expect(sellResult1.remainingHoldingQty, equals(15));
      expect(sellResult1.remainingBalance, equals(const Money(5725000))); // ₹57,250.00

      holding = await holdingRepo.getHoldingBySymbol(StockConstants.reliance);
      expect(holding!.quantity, equals(15));
      expect(holding.averageCost, equals(const Money(285000))); // Avg cost unchanged on sell

      // 5. Sell remaining 15 shares of RELIANCE (+₹42,750.00 returned to wallet)
      final sellResult2 = await tradingService.executeTrade(
        symbol: StockConstants.reliance,
        side: OrderSide.sell,
        quantity: 15,
      );

      expect(sellResult2.remainingHoldingQty, equals(0));
      expect(sellResult2.remainingBalance, equals(const Money(10000000))); // Full ₹1,00,000.00 restored

      // Verify holding is completely cleared from storage
      final holdingAfterAllSold = await holdingRepo.getHoldingBySymbol(StockConstants.reliance);
      expect(holdingAfterAllSold, isNull);

      // 6. Verify full Order History contains all 4 executed orders sorted newest first
      orders = await orderRepo.getOrders();
      expect(orders.length, equals(4));
      expect(orders[0].id, equals(sellResult2.order.id)); // Newest
      expect(orders[1].id, equals(sellResult1.order.id));
      expect(orders[2].id, equals(buyResult2.order.id));
      expect(orders[3].id, equals(buyResult1.order.id)); // Oldest
    });
  });
}
