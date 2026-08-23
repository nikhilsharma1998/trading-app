import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trading_app/core/constants/stock_constants.dart';
import 'package:trading_app/data/local/local_storage_service.dart';
import 'package:trading_app/data/repositories/repository_providers.dart';
import 'package:trading_app/data/repositories/watchlist_repository_impl.dart';
import 'package:trading_app/features/watchlist/presentation/providers/watchlist_provider.dart';

void main() {
  late LocalStorageService storageService;
  late WatchlistRepositoryImpl repository;

  setUp(() {
    storageService = InMemoryLocalStorageService();
    repository = WatchlistRepositoryImpl(storageService);
  });

  group('Watchlist Flow Integration Tests', () {
    test('complete lifecycle of creating, populating, reordering, and persisting watchlists across sessions', () async {
      // 1. Session 1: Load and create a new custom watchlist
      final container1 = ProviderContainer(
        overrides: [
          watchlistRepositoryProvider.overrideWithValue(repository),
        ],
      );

      final notifier1 = container1.read(watchlistNotifierProvider.notifier);
      await notifier1.loadWatchlists();

      await notifier1.createWatchlist('Bluechip Giants');
      var list1 = container1.read(watchlistNotifierProvider).value!;
      final customWlId = list1.last.id;
      expect(list1.last.name, equals('Bluechip Giants'));

      // Add stocks: RELIANCE, TCS, INFY
      await notifier1.addStockToWatchlist(customWlId, StockConstants.reliance);
      await notifier1.addStockToWatchlist(customWlId, StockConstants.tcs);
      await notifier1.addStockToWatchlist(customWlId, StockConstants.infy);

      // Attempt duplicate addition of TCS
      final duplicateResult = await notifier1.addStockToWatchlist(customWlId, StockConstants.tcs);
      expect(duplicateResult, isFalse); // Successfully blocked

      list1 = container1.read(watchlistNotifierProvider).value!;
      final targetWl = list1.firstWhere((w) => w.id == customWlId);
      expect(targetWl.symbols, equals([StockConstants.reliance, StockConstants.tcs, StockConstants.infy]));

      // Reorder INFY (index 2) to first position (index 0)
      await notifier1.reorderStocks(customWlId, 2, 0);

      list1 = container1.read(watchlistNotifierProvider).value!;
      final reorderedWl = list1.firstWhere((w) => w.id == customWlId);
      expect(reorderedWl.symbols, equals([StockConstants.infy, StockConstants.reliance, StockConstants.tcs]));

      // Set as active watchlist
      container1.read(activeWatchlistIdProvider.notifier).state = customWlId;
      await repository.saveActiveWatchlistId(customWlId);

      container1.dispose();

      // 2. Session 2 (Simulated App Restart): New container reading from same storage
      final container2 = ProviderContainer(
        overrides: [
          watchlistRepositoryProvider.overrideWithValue(repository),
        ],
      );

      final notifier2 = container2.read(watchlistNotifierProvider.notifier);
      await notifier2.loadWatchlists();

      final list2 = container2.read(watchlistNotifierProvider).value!;
      expect(list2.any((w) => w.id == customWlId), isTrue);

      final restoredWl = list2.firstWhere((w) => w.id == customWlId);
      expect(restoredWl.name, equals('Bluechip Giants'));
      expect(restoredWl.symbols, equals([StockConstants.infy, StockConstants.reliance, StockConstants.tcs]));

      // Verify active watchlist restored
      final activeId = container2.read(activeWatchlistIdProvider);
      expect(activeId, equals(customWlId));

      container2.dispose();
    });
  });
}
