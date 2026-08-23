import '../../../../core/money/money.dart';

enum OrderSide {
  buy,
  sell;

  bool get isBuy => this == OrderSide.buy;
  bool get isSell => this == OrderSide.sell;

  String get label => this == OrderSide.buy ? 'BUY' : 'SELL';
}

enum OrderStatus {
  completed,
  failed;

  String get label => this == OrderStatus.completed ? 'SUCCESS' : 'FAILED';
}

/// Represents an executed or recorded stock order
class Order {
  final String id;
  final String symbol;
  final OrderSide side;
  final int quantity;
  final Money price;
  final Money totalValue;
  final DateTime timestamp;
  final OrderStatus status;

  const Order({
    required this.id,
    required this.symbol,
    required this.side,
    required this.quantity,
    required this.price,
    required this.totalValue,
    required this.timestamp,
    this.status = OrderStatus.completed,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Order &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          symbol == other.symbol &&
          side == other.side &&
          quantity == other.quantity &&
          price == other.price &&
          totalValue == other.totalValue &&
          timestamp == other.timestamp &&
          status == other.status;

  @override
  int get hashCode =>
      id.hashCode ^
      symbol.hashCode ^
      side.hashCode ^
      quantity.hashCode ^
      price.hashCode ^
      totalValue.hashCode ^
      timestamp.hashCode ^
      status.hashCode;
}
