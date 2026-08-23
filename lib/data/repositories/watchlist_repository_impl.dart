import '../../core/constants/stock_constants.dart';
import '../../features/watchlist/data/models/watchlist_model.dart';
import '../../features/watchlist/domain/entities/watchlist.dart';
import '../../features/watchlist/domain/repositories/watchlist_repository.dart';
import '../local/local_storage_keys.dart';
import '../local/local_storage_service.dart';

class WatchlistRepositoryImpl implements WatchlistRepository {
  final LocalStorageService _storageService;

  WatchlistRepositoryImpl(this._storageService);

  @override
  Future<List<Watchlist>> getWatchlists() async {
    final raw = _storageService.get(LocalStorageKeys.watchlistsKey);
    if (raw == null || raw is! List || raw.isEmpty) {
      // Seed default initial watchlists
      final initialWatchlists = [
        const Watchlist(
          id: 'watchlist_default',
          name: 'Nifty 50 Leaders',
          symbols: [
            StockConstants.reliance,
            StockConstants.tcs,
            StockConstants.infy,
            StockConstants.hdfcBank,
            StockConstants.iciciBank,
          ],
        ),
        const Watchlist(
          id: 'watchlist_banking_fmcg',
          name: 'Banking & FMCG',
          symbols: [
            StockConstants.hdfcBank,
            StockConstants.iciciBank,
            StockConstants.sbin,
            StockConstants.axisBank,
            StockConstants.itc,
          ],
        ),
        const Watchlist(
          id: 'watchlist_infra_tech',
          name: 'Infra & Tech',
          symbols: [
            StockConstants.lt,
            StockConstants.bhartiAirtel,
            StockConstants.reliance,
            StockConstants.tcs,
            StockConstants.infy,
          ],
        ),
      ];

      await saveWatchlists(initialWatchlists);
      await saveActiveWatchlistId(initialWatchlists.first.id);
      return initialWatchlists;
    }

    try {
      final list = raw.map((item) {
        if (item is Map<String, dynamic>) {
          return WatchlistModel.fromJson(item).toDomain();
        } else if (item is Map) {
          return WatchlistModel.fromJson(Map<String, dynamic>.from(item)).toDomain();
        }
        throw FormatException('Invalid watchlist record: $item');
      }).toList();

      return list;
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> saveWatchlists(List<Watchlist> watchlists) async {
    final models = watchlists.map((w) => WatchlistModel.fromDomain(w).toJson()).toList();
    await _storageService.put(LocalStorageKeys.watchlistsKey, models);
  }

  @override
  Future<String?> getActiveWatchlistId() async {
    final id = _storageService.get(LocalStorageKeys.activeWatchlistIdKey);
    return id is String ? id : null;
  }

  @override
  Future<void> saveActiveWatchlistId(String watchlistId) async {
    await _storageService.put(LocalStorageKeys.activeWatchlistIdKey, watchlistId);
  }
}
