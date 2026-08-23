import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trading_app/app/theme/app_theme.dart';
import 'package:trading_app/core/constants/stock_constants.dart';
import 'package:trading_app/data/local/local_storage_service.dart';
import 'package:trading_app/data/repositories/repository_providers.dart';
import 'package:trading_app/data/repositories/watchlist_repository_impl.dart';
import 'package:trading_app/features/watchlist/presentation/providers/watchlist_provider.dart';
import 'package:trading_app/features/watchlist/presentation/screens/watchlist_screen.dart';

void main() {
  late LocalStorageService storageService;
  late WatchlistRepositoryImpl repository;

  setUp(() {
    storageService = InMemoryLocalStorageService();
    repository = WatchlistRepositoryImpl(storageService);
  });

  group('WatchlistNotifier Unit Tests', () {
    test('creates, renames, and deletes watchlists', () async {
      final container = ProviderContainer(
        overrides: [
          watchlistRepositoryProvider.overrideWithValue(repository),
        ],
      );

      final notifier = container.read(watchlistNotifierProvider.notifier);
      await notifier.loadWatchlists();

      var list = container.read(watchlistNotifierProvider).value!;
      expect(list.length, equals(3)); // Initial seeded watchlists

      // Create new watchlist
      await notifier.createWatchlist('My Crypto & Stocks');
      list = container.read(watchlistNotifierProvider).value!;
      expect(list.length, equals(4));
      expect(list.last.name, equals('My Crypto & Stocks'));
      expect(container.read(activeWatchlistIdProvider), equals(list.last.id));

      // Rename watchlist
      final newWlId = list.last.id;
      await notifier.renameWatchlist(newWlId, 'High Growth Stocks');
      list = container.read(watchlistNotifierProvider).value!;
      expect(list.firstWhere((w) => w.id == newWlId).name, equals('High Growth Stocks'));

      // Delete watchlist
      await notifier.deleteWatchlist(newWlId);
      list = container.read(watchlistNotifierProvider).value!;
      expect(list.length, equals(3));
      expect(list.any((w) => w.id == newWlId), isFalse);

      container.dispose();
    });

    test('adds stock, blocks duplicates, removes stock, and reorders', () async {
      final container = ProviderContainer(
        overrides: [
          watchlistRepositoryProvider.overrideWithValue(repository),
        ],
      );

      final notifier = container.read(watchlistNotifierProvider.notifier);
      await notifier.loadWatchlists();

      final list = container.read(watchlistNotifierProvider).value!;
      final targetId = list.first.id;

      // Add new stock
      final addResult1 = await notifier.addStockToWatchlist(targetId, StockConstants.bhartiAirtel);
      expect(addResult1, isTrue);

      // Block duplicate stock
      final addResult2 = await notifier.addStockToWatchlist(targetId, StockConstants.bhartiAirtel);
      expect(addResult2, isFalse);

      // Remove stock
      await notifier.removeStockFromWatchlist(targetId, StockConstants.bhartiAirtel);
      final updatedList = container.read(watchlistNotifierProvider).value!;
      expect(updatedList.first.symbols.contains(StockConstants.bhartiAirtel), isFalse);

      // Reorder stocks
      final originalFirst = updatedList.first.symbols[0];
      final originalSecond = updatedList.first.symbols[1];

      await notifier.reorderStocks(targetId, 0, 2);
      final reordered = container.read(watchlistNotifierProvider).value!;
      expect(reordered.first.symbols[0], equals(originalSecond));
      expect(reordered.first.symbols[1], equals(originalFirst));

      container.dispose();
    });
  });

  group('WatchlistScreen Widget Tests', () {
    testWidgets('renders watchlist chips, stock rows, and triggers stock picker', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            watchlistRepositoryProvider.overrideWithValue(repository),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const WatchlistScreen(),
          ),
        ),
      );

      // Wait for initial async loading
      await tester.pumpAndSettle();

      // Check App bar
      expect(find.text('Watchlists'), findsOneWidget);

      // Check tab chip
      expect(find.text('Nifty 50 Leaders'), findsOneWidget);

      // Check stock row
      expect(find.byKey(const ValueKey('wl_watchlist_default_RELIANCE')), findsOneWidget);

      // Open Stock Picker
      await tester.tap(find.text('Add Stock'));
      await tester.pumpAndSettle();

      expect(find.text('Add Stocks to Watchlist'), findsOneWidget);
    });
  });
}
