import '../../features/trading/data/models/order_model.dart';
import '../../features/trading/domain/entities/order.dart';
import '../../features/trading/domain/repositories/order_repository.dart';
import '../local/local_storage_keys.dart';
import '../local/local_storage_service.dart';

class OrderRepositoryImpl implements OrderRepository {
  final LocalStorageService _storageService;

  OrderRepositoryImpl(this._storageService);

  @override
  Future<List<Order>> getOrders() async {
    final raw = _storageService.get(LocalStorageKeys.ordersKey);
    if (raw == null || raw is! List) return [];

    final List<Order> orders = [];
    for (final item in raw) {
      if (item is Map<String, dynamic>) {
        orders.add(OrderModel.fromJson(item).toDomain());
      } else if (item is Map) {
        orders.add(OrderModel.fromJson(Map<String, dynamic>.from(item)).toDomain());
      }
    }

    // Sort newest orders first
    orders.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return orders;
  }

  @override
  Future<void> saveOrder(Order order) async {
    final current = await getOrders();
    // Insert at front
    current.insert(0, order);
    final serialized = current.map((o) => OrderModel.fromDomain(o).toJson()).toList();
    await _storageService.put(LocalStorageKeys.ordersKey, serialized);
  }
}
