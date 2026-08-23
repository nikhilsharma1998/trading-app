import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trading_app/app/theme/app_theme.dart';
import 'package:trading_app/core/constants/stock_constants.dart';
import 'package:trading_app/features/market/presentation/screens/market_overview_screen.dart';


void main() {
  testWidgets('MarketOverviewScreen displays stock list and handles search', (WidgetTester tester) async {
    String? selectedStock;

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: MarketOverviewScreen(
            onStockSelected: (symbol) {
              selectedStock = symbol;
            },
          ),
        ),
      ),
    );

    await tester.pump();

    // Verifies header elements
    expect(find.text('Market Overview'), findsOneWidget);
    expect(find.text('LIVE'), findsOneWidget);
    expect(find.text('10 NIFTY Instruments'), findsOneWidget);

    // Verifies stock symbols in tiles
    expect(find.byKey(const ValueKey('market_tile_RELIANCE')), findsOneWidget);
    expect(find.byKey(const ValueKey('market_tile_TCS')), findsOneWidget);

    // Test search functionality
    await tester.enterText(find.byType(TextField), 'RELIANCE');
    await tester.pump();

    expect(find.byKey(const ValueKey('market_tile_RELIANCE')), findsOneWidget);
    expect(find.byKey(const ValueKey('market_tile_TCS')), findsNothing);

    // Clear search
    await tester.tap(find.byIcon(Icons.clear));
    await tester.pump();

    expect(find.byKey(const ValueKey('market_tile_TCS')), findsOneWidget);

    // Tap on a stock item
    await tester.tap(find.byKey(const ValueKey('market_tile_RELIANCE')));
    await tester.pump();

    expect(selectedStock, equals(StockConstants.reliance));
  });
}
