import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trading_app/app/app.dart';

void main() {
  testWidgets('TradingApp initializes and renders Market tab', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: TradingApp(),
      ),
    );

    // Initial pump and settle
    await tester.pump();

    // Verifies bottom navigation items
    expect(find.text('Market'), findsWidgets);
    expect(find.text('Watchlists'), findsOneWidget);
    expect(find.text('Portfolio'), findsOneWidget);
    expect(find.text('Orders'), findsOneWidget);

    // Verifies top title and search
    expect(find.text('Market Overview'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });
}
