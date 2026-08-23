import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trading_app/app/app.dart';

void main() {
  testWidgets('TradingApp initializes properly', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: TradingApp(),
      ),
    );

    expect(find.text('Trading App Initialized'), findsOneWidget);
  });
}

