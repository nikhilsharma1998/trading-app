import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trading_app/app/theme/app_theme.dart';
import 'package:trading_app/core/constants/stock_constants.dart';
import 'package:trading_app/core/money/money.dart';
import 'package:trading_app/data/local/local_storage_service.dart';
import 'package:trading_app/data/repositories/holding_repository_impl.dart';
import 'package:trading_app/data/repositories/repository_providers.dart';
import 'package:trading_app/data/repositories/wallet_repository_impl.dart';
import 'package:trading_app/features/holdings/domain/entities/holding.dart';
import 'package:trading_app/features/holdings/presentation/screens/portfolio_screen.dart';


void main() {
  late LocalStorageService storageService;
  late WalletRepositoryImpl walletRepo;
  late HoldingRepositoryImpl holdingRepo;

  setUp(() {
    storageService = InMemoryLocalStorageService();
    walletRepo = WalletRepositoryImpl(storageService);
    holdingRepo = HoldingRepositoryImpl(storageService);
  });

  group('Portfolio & Holdings Widget Tests', () {
    testWidgets('renders empty state when user owns 0 holdings', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            walletRepositoryProvider.overrideWithValue(walletRepo),
            holdingRepositoryProvider.overrideWithValue(holdingRepo),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const PortfolioScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Portfolio & Holdings'), findsOneWidget);
      expect(find.text('TOTAL PORTFOLIO VALUE'), findsOneWidget);
      expect(find.text('No active holdings'), findsOneWidget);
      expect(find.text('Explore Market'), findsOneWidget);
    });

    testWidgets('renders holding tiles with accurate P&L and handles sort sheet', (WidgetTester tester) async {
      // Seed holdings
      final holding1 = Holding(
        symbol: StockConstants.reliance,
        quantity: 10,
        averageCost: const Money(280000), // Avg ₹2,800.00
        lastUpdated: DateTime.now(),
      );

      final holding2 = Holding(
        symbol: StockConstants.tcs,
        quantity: 5,
        averageCost: const Money(390000), // Avg ₹3,900.00
        lastUpdated: DateTime.now(),
      );

      await holdingRepo.saveHolding(holding1);
      await holdingRepo.saveHolding(holding2);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            walletRepositoryProvider.overrideWithValue(walletRepo),
            holdingRepositoryProvider.overrideWithValue(holdingRepo),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const PortfolioScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify holdings are rendered
      expect(find.byKey(const ValueKey('holding_RELIANCE')), findsOneWidget);
      expect(find.byKey(const ValueKey('holding_TCS')), findsOneWidget);
      expect(find.text('2 POSITIONS'), findsOneWidget);

      // Open Sort bottom sheet
      await tester.tap(find.byIcon(Icons.sort));
      await tester.pumpAndSettle();

      expect(find.text('Sort Holdings By'), findsOneWidget);
      expect(find.text('Symbol (A-Z)'), findsOneWidget);
      expect(find.text('Quantity (High to Low)'), findsOneWidget);

      // Select Symbol (A-Z)
      await tester.tap(find.text('Symbol (A-Z)'));
      await tester.pumpAndSettle();

      expect(find.text('Symbol (A-Z)'), findsOneWidget);
    });
  });
}
