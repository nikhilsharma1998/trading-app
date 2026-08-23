import '../entities/watchlist.dart';

abstract class WatchlistRepository {
  /// Loads all saved watchlists from persistent storage.
  /// If empty, initializes with a default watchlist.
  Future<List<Watchlist>> getWatchlists();

  /// Saves the complete list of watchlists to storage.
  Future<void> saveWatchlists(List<Watchlist> watchlists);

  /// Gets the currently selected watchlist ID if saved.
  Future<String?> getActiveWatchlistId();

  /// Persists the currently selected watchlist ID.
  Future<void> saveActiveWatchlistId(String watchlistId);
}
