import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trading_app/app/theme/app_theme.dart';
import 'package:trading_app/core/constants/stock_constants.dart';
import 'package:trading_app/features/market/data/services/mock_market_feed.dart';
import 'package:trading_app/features/market/domain/repositories/market_repository.dart';
import 'package:trading_app/features/market/presentation/providers/market_feed_provider.dart';
import 'package:trading_app/features/market/presentation/widgets/market_stock_tile.dart';

class _StockBuildTracker extends ConsumerWidget {
  final String symbol;
  final VoidCallback onBuild;

  const _StockBuildTracker({
    super.key,
    required this.symbol,
    required this.onBuild,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(stockTickProvider(symbol));
    onBuild();
    return MarketStockTile(
      key: ValueKey('market_tile_$symbol'),
      symbol: symbol,
    );
  }
}

void main() {
  group('High-Frequency Rebuild Optimizations Tests', () {
    testWidgets('a tick on RELIANCE rebuilds ONLY the RELIANCE tile and NOT TCS or INFY', (WidgetTester tester) async {
      final feed = MockMarketFeed();

      int relianceBuildCount = 0;
      int tcsBuildCount = 0;

      final container = ProviderContainer(
        overrides: [
          mockMarketFeedProvider.overrideWithValue(feed),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: Scaffold(
              body: Column(
                children: [
                  _StockBuildTracker(
                    key: const ValueKey('tracker_RELIANCE'),
                    symbol: StockConstants.reliance,
                    onBuild: () => relianceBuildCount++,
                  ),
                  _StockBuildTracker(
                    key: const ValueKey('tracker_TCS'),
                    symbol: StockConstants.tcs,
                    onBuild: () => tcsBuildCount++,
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      // Initial build counts
      expect(relianceBuildCount, equals(1));
      expect(tcsBuildCount, equals(1));

      // Emit a price tick on RELIANCE
      feed.tickStock(StockConstants.reliance);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Verify that RELIANCE rebuilt, while TCS was NOT rebuilt
      expect(relianceBuildCount, equals(2));
      expect(tcsBuildCount, equals(1));

      // Emit a price tick on TCS
      feed.tickStock(StockConstants.tcs);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Verify that TCS rebuilt, while RELIANCE remained at 2
      expect(relianceBuildCount, equals(2));
      expect(tcsBuildCount, equals(2));

      container.dispose();
      feed.dispose();
    });

    test('Stress mode generates high-frequency ticks reliably without stream errors', () async {
      final feed = MockMarketFeed();
      feed.setSpeed(MarketFeedSpeed.stress);

      final ticksReceived = <String>[];
      final subscription = feed.tickStream.listen((tick) {
        ticksReceived.add(tick.symbol);
      });

      // Rapidly fire 50 ticks
      for (int i = 0; i < 50; i++) {
        feed.tickStock(StockConstants.allSymbols[i % StockConstants.allSymbols.length]);
      }

      await Future.delayed(const Duration(milliseconds: 50));

      expect(ticksReceived.length, greaterThanOrEqualTo(50));
      expect(feed.priceStore.length, equals(10));

      await subscription.cancel();
      feed.dispose();
    });
  });
}
