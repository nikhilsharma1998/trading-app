import 'package:flutter_test/flutter_test.dart';
import 'package:trading_app/core/constants/stock_constants.dart';
import 'package:trading_app/core/errors/failures.dart';
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

  group('TradingEngine Unit Tests', () {
    test('rejects zero or negative quantities', () async {
      expect(
        () => tradingService.executeTrade(
          symbol: StockConstants.reliance,
          side: OrderSide.buy,
          quantity: 0,
        ),
        throwsA(isA<InvalidQuantityFailure>()),
      );

      expect(
        () => tradingService.executeTrade(
          symbol: StockConstants.reliance,
          side: OrderSide.buy,
          quantity: -5,
        ),
        throwsA(isA<InvalidQuantityFailure>()),
      );
    });

    test('rejects BUY order when order value exceeds wallet balance', () async {
      // Wallet starts with ₹1,00,000 (10,000,000 paise)
      // Buying 100 RELIANCE @ ₹2850 requires ₹2,85,000
      expect(
        () => tradingService.executeTrade(
          symbol: StockConstants.reliance,
          side: OrderSide.buy,
          quantity: 100,
        ),
        throwsA(isA<InsufficientBalanceFailure>()),
      );
    });

    test('executes BUY order, deducts balance, creates holding and order record', () async {
      // Buy 10 RELIANCE @ ₹2850 (₹28,500 = 2850000 paise)
      final result = await tradingService.executeTrade(
        symbol: StockConstants.reliance,
        side: OrderSide.buy,
        quantity: 10,
      );

      expect(result.order.side, equals(OrderSide.buy));
      expect(result.order.symbol, equals(StockConstants.reliance));
      expect(result.order.quantity, equals(10));
      expect(result.order.price, equals(const Money(285000)));
      expect(result.order.totalValue, equals(const Money(2850000)));
      expect(result.remainingBalance.paise, equals(7150000)); // ₹71,500 remaining

      // Verify Holding
      final holding = await holdingRepo.getHoldingBySymbol(StockConstants.reliance);
      expect(holding, isNotNull);
      expect(holding!.quantity, equals(10));
      expect(holding.averageCost, equals(const Money(285000)));

      // Verify Orders
      final orders = await orderRepo.getOrders();
      expect(orders.length, equals(1));
      expect(orders.first.id, equals(result.order.id));
    });

    test('calculates correct weighted average cost on subsequent BUY order', () async {
      // 1. Buy 10 RELIANCE @ ₹2850
      await tradingService.executeTrade(
        symbol: StockConstants.reliance,
        side: OrderSide.buy,
        quantity: 10,
      );

      // 2. Buy additional 10 RELIANCE @ ₹2850 (total 20 @ ₹2850)
      final result2 = await tradingService.executeTrade(
        symbol: StockConstants.reliance,
        side: OrderSide.buy,
        quantity: 10,
      );

      expect(result2.remainingHoldingQty, equals(20));

      final holding = await holdingRepo.getHoldingBySymbol(StockConstants.reliance);
      expect(holding!.quantity, equals(20));
      expect(holding.averageCost, equals(const Money(285000))); // 285000
      expect(holding.investedValue, equals(const Money(5700000))); // ₹57,000.00
    });

    test('rejects SELL order when selling more shares than held', () async {
      // Hold 0 shares initially
      expect(
        () => tradingService.executeTrade(
          symbol: StockConstants.tcs,
          side: OrderSide.sell,
          quantity: 5,
        ),
        throwsA(isA<InsufficientHoldingsFailure>()),
      );
    });

    test('executes SELL order, credits wallet balance and removes holding on full sale', () async {
      // 1. Buy 5 TCS @ ₹3920 (₹19,600)
      await tradingService.executeTrade(
        symbol: StockConstants.tcs,
        side: OrderSide.buy,
        quantity: 5,
      );

      // Wallet = ₹80,400 (8040000 paise)
      var wallet = await walletRepo.getWallet();
      expect(wallet.balance.paise, equals(8040000));

      // 2. Sell all 5 TCS @ ₹3920
      final sellResult = await tradingService.executeTrade(
        symbol: StockConstants.tcs,
        side: OrderSide.sell,
        quantity: 5,
      );

      expect(sellResult.order.side, equals(OrderSide.sell));
      expect(sellResult.remainingHoldingQty, equals(0));
      expect(sellResult.remainingBalance.paise, equals(10000000)); // Restored to ₹1,00,000

      // Verify holding is completely removed
      final holding = await holdingRepo.getHoldingBySymbol(StockConstants.tcs);
      expect(holding, isNull);
    });
  });
}
