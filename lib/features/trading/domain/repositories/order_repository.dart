import '../entities/order.dart';

abstract class OrderRepository {
  /// Returns list of all persisted orders sorted by timestamp descending
  Future<List<Order>> getOrders();

  /// Adds a newly executed order to persistent storage
  Future<void> saveOrder(Order order);
}
