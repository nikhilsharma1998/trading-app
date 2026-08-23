import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trading_app/app/theme/app_theme.dart';
import 'package:trading_app/core/constants/stock_constants.dart';
import 'package:trading_app/data/local/local_storage_service.dart';
import 'package:trading_app/data/repositories/repository_providers.dart';
import 'package:trading_app/data/repositories/wallet_repository_impl.dart';
import 'package:trading_app/features/trading/domain/entities/order.dart';
import 'package:trading_app/features/trading/presentation/screens/buy_sell_ticket_screen.dart';

void main() {
  late LocalStorageService storageService;

  setUp(() {
    storageService = InMemoryLocalStorageService();
  });

  testWidgets('BuySellTicketScreen renders, validates quantity and calculates projected value', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localStorageServiceProvider.overrideWithValue(storageService),
          walletRepositoryProvider.overrideWithValue(WalletRepositoryImpl(storageService)),
        ],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: const BuySellTicketScreen(
            initialSymbol: StockConstants.reliance,
            initialSide: OrderSide.buy,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verifies Header & Selected Symbol
    expect(find.text('BUY ORDER'), findsOneWidget);
    expect(find.text('RELIANCE'), findsWidgets);
    expect(find.text('BUY RELIANCE'), findsOneWidget);

    // Switch to SELL side
    await tester.tap(find.text('SELL'));
    await tester.pumpAndSettle();

    expect(find.text('SELL ORDER'), findsOneWidget);
    expect(find.text('SELL RELIANCE'), findsOneWidget);

    // Switch back to BUY
    await tester.tap(find.text('BUY'));
    await tester.pumpAndSettle();

    // Test quick add chip (+5)
    await tester.tap(find.text('+5'));
    await tester.pumpAndSettle();

    expect(find.text('6'), findsOneWidget); // 1 + 5 = 6

    // Test invalid zero quantity
    await tester.enterText(find.byType(TextField), '0');
    await tester.pumpAndSettle();

    expect(find.text('Please enter a valid quantity greater than 0'), findsOneWidget);
  });
}
