import '../../features/holdings/data/models/holding_model.dart';
import '../../features/holdings/domain/entities/holding.dart';
import '../../features/holdings/domain/repositories/holding_repository.dart';
import '../local/local_storage_keys.dart';
import '../local/local_storage_service.dart';

class HoldingRepositoryImpl implements HoldingRepository {
  final LocalStorageService _storageService;

  HoldingRepositoryImpl(this._storageService);

  @override
  Future<Map<String, Holding>> getHoldings() async {
    final raw = _storageService.get(LocalStorageKeys.holdingsKey);
    if (raw == null) return {};

    final Map<String, Holding> result = {};

    if (raw is Map) {
      raw.forEach((key, value) {
        if (value is Map<String, dynamic>) {
          result[key.toString()] = HoldingModel.fromJson(value).toDomain();
        } else if (value is Map) {
          result[key.toString()] =
              HoldingModel.fromJson(Map<String, dynamic>.from(value)).toDomain();
        }
      });
    } else if (raw is List) {
      for (final item in raw) {
        if (item is Map<String, dynamic>) {
          final h = HoldingModel.fromJson(item).toDomain();
          result[h.symbol] = h;
        } else if (item is Map) {
          final h = HoldingModel.fromJson(Map<String, dynamic>.from(item)).toDomain();
          result[h.symbol] = h;
        }
      }
    }

    return result;
  }

  @override
  Future<Holding?> getHoldingBySymbol(String symbol) async {
    final all = await getHoldings();
    return all[symbol];
  }

  @override
  Future<void> saveHolding(Holding holding) async {
    final current = await getHoldings();
    current[holding.symbol] = holding;
    await saveAllHoldings(current);
  }

  @override
  Future<void> removeHolding(String symbol) async {
    final current = await getHoldings();
    if (current.containsKey(symbol)) {
      current.remove(symbol);
      await saveAllHoldings(current);
    }
  }

  @override
  Future<void> saveAllHoldings(Map<String, Holding> holdings) async {
    final serialized = holdings.map(
      (key, value) => MapEntry(key, HoldingModel.fromDomain(value).toJson()),
    );
    await _storageService.put(LocalStorageKeys.holdingsKey, serialized);
  }
}
