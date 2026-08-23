import '../../../../core/money/money.dart';
import '../../domain/entities/order.dart';

class OrderModel {
  final String id;
  final String symbol;
  final String side;
  final int quantity;
  final int pricePaise;
  final int totalValuePaise;
  final int timestampMillis;
  final String status;

  const OrderModel({
    required this.id,
    required this.symbol,
    required this.side,
    required this.quantity,
    required this.pricePaise,
    required this.totalValuePaise,
    required this.timestampMillis,
    this.status = 'completed',
  });

  factory OrderModel.fromDomain(Order order) {
    return OrderModel(
      id: order.id,
      symbol: order.symbol,
      side: order.side.name,
      quantity: order.quantity,
      pricePaise: order.price.paise,
      totalValuePaise: order.totalValue.paise,
      timestampMillis: order.timestamp.millisecondsSinceEpoch,
      status: order.status.name,
    );
  }

  Order toDomain() {
    return Order(
      id: id,
      symbol: symbol,
      side: side == 'buy' ? OrderSide.buy : OrderSide.sell,
      quantity: quantity,
      price: Money(pricePaise),
      totalValue: Money(totalValuePaise),
      timestamp: DateTime.fromMillisecondsSinceEpoch(timestampMillis),
      status: status == 'failed' ? OrderStatus.failed : OrderStatus.completed,
    );
  }

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'] as String,
      symbol: json['symbol'] as String,
      side: json['side'] as String,
      quantity: json['quantity'] as int,
      pricePaise: json['pricePaise'] as int,
      totalValuePaise: json['totalValuePaise'] as int,
      timestampMillis: json['timestampMillis'] as int,
      status: json['status'] as String? ?? 'completed',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'symbol': symbol,
      'side': side,
      'quantity': quantity,
      'pricePaise': pricePaise,
      'totalValuePaise': totalValuePaise,
      'timestampMillis': timestampMillis,
      'status': status,
    };
  }
}
