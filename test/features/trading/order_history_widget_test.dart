import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trading_app/app/theme/app_theme.dart';
import 'package:trading_app/core/constants/stock_constants.dart';
import 'package:trading_app/core/money/money.dart';
import 'package:trading_app/data/local/local_storage_service.dart';
import 'package:trading_app/data/repositories/order_repository_impl.dart';
import 'package:trading_app/data/repositories/repository_providers.dart';
import 'package:trading_app/features/trading/domain/entities/order.dart';
import 'package:trading_app/features/trading/domain/entities/trade_execution_result.dart';
import 'package:trading_app/features/trading/presentation/screens/order_confirmation_screen.dart';
import 'package:trading_app/features/trading/presentation/screens/order_history_screen.dart';

void main() {
  late LocalStorageService storageService;
  late OrderRepositoryImpl orderRepo;

  setUp(() {
    storageService = InMemoryLocalStorageService();
    orderRepo = OrderRepositoryImpl(storageService);
  });

  group('OrderHistoryScreen Widget Tests', () {
    testWidgets('shows empty state when no orders exist', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            orderRepositoryProvider.overrideWithValue(orderRepo),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const OrderHistoryScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('No orders placed yet'), findsOneWidget);
      expect(find.text('Explore Market'), findsOneWidget);
    });

    testWidgets('renders orders, filters by BUY/SELL, and searches by symbol', (WidgetTester tester) async {
      // Seed some orders
      final order1 = Order(
        id: 'ord-1111',
        symbol: StockConstants.reliance,
        side: OrderSide.buy,
        quantity: 10,
        price: const Money(285000),
        totalValue: const Money(2850000),
        timestamp: DateTime.now(),
        status: OrderStatus.completed,
      );

      final order2 = Order(
        id: 'ord-2222',
        symbol: StockConstants.tcs,
        side: OrderSide.sell,
        quantity: 5,
        price: const Money(392000),
        totalValue: const Money(1960000),
        timestamp: DateTime.now(),
        status: OrderStatus.completed,
      );

      await orderRepo.saveOrder(order1);
      await orderRepo.saveOrder(order2);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            orderRepositoryProvider.overrideWithValue(orderRepo),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const OrderHistoryScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify both order keys rendered
      expect(find.byKey(const ValueKey('order_ord-1111')), findsOneWidget);
      expect(find.byKey(const ValueKey('order_ord-2222')), findsOneWidget);
      expect(find.text('2 ORDERS'), findsOneWidget);

      // Filter: Buy Only
      await tester.tap(find.text('Buy Only'));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('order_ord-1111')), findsOneWidget);
      expect(find.byKey(const ValueKey('order_ord-2222')), findsNothing);
      expect(find.text('1 ORDERS'), findsOneWidget);

      // Filter: Sell Only
      await tester.tap(find.text('Sell Only'));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('order_ord-1111')), findsNothing);
      expect(find.byKey(const ValueKey('order_ord-2222')), findsOneWidget);

      // Reset to All
      await tester.tap(find.text('All'));
      await tester.pumpAndSettle();

      // Search by TCS
      await tester.enterText(find.byType(TextField), 'TCS');
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('order_ord-1111')), findsNothing);
      expect(find.byKey(const ValueKey('order_ord-2222')), findsOneWidget);
    });

    testWidgets('OrderConfirmationScreen renders full order breakdown and buttons', (WidgetTester tester) async {
      final mockOrder = Order(
        id: 'ord-12345678',
        symbol: StockConstants.reliance,
        side: OrderSide.buy,
        quantity: 10,
        price: const Money(285000),
        totalValue: const Money(2850000),
        timestamp: DateTime.now(),
        status: OrderStatus.completed,
      );

      final result = TradeExecutionResult(
        order: mockOrder,
        remainingBalance: const Money(7150000),
        remainingHoldingQty: 10,
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: OrderConfirmationScreen(result: result),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Order Executed Successfully'), findsOneWidget);
      expect(find.text(StockConstants.reliance), findsOneWidget);
      expect(find.text('View Holdings / Portfolio'), findsOneWidget);
      expect(find.text('View Order History'), findsOneWidget);
      expect(find.text('Back to Market'), findsOneWidget);
    });

  });
}
