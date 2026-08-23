import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../data/repositories/repository_providers.dart';
import '../../domain/entities/watchlist.dart';
import '../../domain/repositories/watchlist_repository.dart';

/// State of all user watchlists
class WatchlistNotifier extends StateNotifier<AsyncValue<List<Watchlist>>> {
  final WatchlistRepository _repository;
  final Ref _ref;

  WatchlistNotifier(this._repository, this._ref)
      : super(const AsyncValue.loading()) {
    loadWatchlists();
  }

  Future<void> loadWatchlists() async {
    try {
      final watchlists = await _repository.getWatchlists();
      state = AsyncValue.data(watchlists);

      // On app launch / restart, default to the primary first watchlist (Nifty 50 Leaders)
      final currentActiveId = _ref.read(activeWatchlistIdProvider);
      if (currentActiveId.isEmpty || !watchlists.any((w) => w.id == currentActiveId)) {
        if (watchlists.isNotEmpty) {
          _ref.read(activeWatchlistIdProvider.notifier).state = watchlists.first.id;
        }
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<List<Watchlist>> _getCurrentList() async {
    if (state.hasValue && state.value != null && state.value!.isNotEmpty) {
      return state.value!;
    }
    return await _repository.getWatchlists();
  }

  Future<void> createWatchlist(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;

    final currentList = await _getCurrentList();
    final newWatchlist = Watchlist(
      id: const Uuid().v4(),
      name: trimmed,
      symbols: [],
    );

    final updated = [...currentList, newWatchlist];
    state = AsyncValue.data(updated);
    await _repository.saveWatchlists(updated);

    // Switch to newly created watchlist
    _ref.read(activeWatchlistIdProvider.notifier).state = newWatchlist.id;
    await _repository.saveActiveWatchlistId(newWatchlist.id);
  }

  Future<void> renameWatchlist(String id, String newName) async {
    final trimmed = newName.trim();
    if (trimmed.isEmpty) return;

    final currentList = await _getCurrentList();
    final updated = currentList.map((w) {
      if (w.id == id) {
        return w.copyWith(name: trimmed);
      }
      return w;
    }).toList();

    state = AsyncValue.data(updated);
    await _repository.saveWatchlists(updated);
  }

  Future<void> deleteWatchlist(String id) async {
    final currentList = await _getCurrentList();
    if (currentList.length <= 1) {
      // Must maintain at least one watchlist
      return;
    }

    final updated = currentList.where((w) => w.id != id).toList();
    state = AsyncValue.data(updated);
    await _repository.saveWatchlists(updated);

    final activeId = _ref.read(activeWatchlistIdProvider);
    if (activeId == id && updated.isNotEmpty) {
      _ref.read(activeWatchlistIdProvider.notifier).state = updated.first.id;
      await _repository.saveActiveWatchlistId(updated.first.id);
    }
  }

  Future<bool> addStockToWatchlist(String watchlistId, String symbol) async {
    final currentList = await _getCurrentList();
    final watchlistIndex = currentList.indexWhere((w) => w.id == watchlistId);
    if (watchlistIndex == -1) return false;

    final target = currentList[watchlistIndex];
    if (target.containsSymbol(symbol)) {
      return false; // Duplicate blocked
    }

    final updatedSymbols = [...target.symbols, symbol];
    final updatedWatchlist = target.copyWith(symbols: updatedSymbols);

    final updatedList = List<Watchlist>.from(currentList);
    updatedList[watchlistIndex] = updatedWatchlist;

    state = AsyncValue.data(updatedList);
    await _repository.saveWatchlists(updatedList);
    return true;
  }

  Future<void> removeStockFromWatchlist(String watchlistId, String symbol) async {
    final currentList = await _getCurrentList();
    final watchlistIndex = currentList.indexWhere((w) => w.id == watchlistId);
    if (watchlistIndex == -1) return;

    final target = currentList[watchlistIndex];
    final updatedSymbols = target.symbols.where((s) => s != symbol).toList();
    final updatedWatchlist = target.copyWith(symbols: updatedSymbols);

    final updatedList = List<Watchlist>.from(currentList);
    updatedList[watchlistIndex] = updatedWatchlist;

    state = AsyncValue.data(updatedList);
    await _repository.saveWatchlists(updatedList);
  }

  Future<void> reorderStocks(String watchlistId, int oldIndex, int newIndex) async {
    final currentList = await _getCurrentList();
    final watchlistIndex = currentList.indexWhere((w) => w.id == watchlistId);
    if (watchlistIndex == -1) return;

    final target = currentList[watchlistIndex];
    final mutableSymbols = List<String>.from(target.symbols);

    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = mutableSymbols.removeAt(oldIndex);
    mutableSymbols.insert(newIndex, item);

    final updatedWatchlist = target.copyWith(symbols: mutableSymbols);
    final updatedList = List<Watchlist>.from(currentList);
    updatedList[watchlistIndex] = updatedWatchlist;

    state = AsyncValue.data(updatedList);
    await _repository.saveWatchlists(updatedList);
  }
}

final watchlistNotifierProvider =
    StateNotifierProvider<WatchlistNotifier, AsyncValue<List<Watchlist>>>((ref) {
  final repository = ref.watch(watchlistRepositoryProvider);
  return WatchlistNotifier(repository, ref);
});

/// Selected active watchlist ID provider
final activeWatchlistIdProvider = StateProvider<String>((ref) => '');

/// Active Watchlist entity provider
final activeWatchlistProvider = Provider<Watchlist?>((ref) {
  final watchlistsState = ref.watch(watchlistNotifierProvider);
  final activeId = ref.watch(activeWatchlistIdProvider);

  return watchlistsState.when(
    data: (list) {
      if (list.isEmpty) return null;
      return list.firstWhere(
        (w) => w.id == activeId,
        orElse: () => list.first,
      );
    },
    loading: () => null,
    error: (err, st) => null,
  );
});
