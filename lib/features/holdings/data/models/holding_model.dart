import '../../../../core/money/money.dart';
import '../../domain/entities/holding.dart';

class HoldingModel {
  final String symbol;
  final int quantity;
  final int averageCostPaise;
  final int lastUpdatedMillis;

  const HoldingModel({
    required this.symbol,
    required this.quantity,
    required this.averageCostPaise,
    required this.lastUpdatedMillis,
  });

  factory HoldingModel.fromDomain(Holding holding) {
    return HoldingModel(
      symbol: holding.symbol,
      quantity: holding.quantity,
      averageCostPaise: holding.averageCost.paise,
      lastUpdatedMillis: holding.lastUpdated.millisecondsSinceEpoch,
    );
  }

  Holding toDomain() {
    return Holding(
      symbol: symbol,
      quantity: quantity,
      averageCost: Money(averageCostPaise),
      lastUpdated: DateTime.fromMillisecondsSinceEpoch(lastUpdatedMillis),
    );
  }

  factory HoldingModel.fromJson(Map<String, dynamic> json) {
    return HoldingModel(
      symbol: json['symbol'] as String,
      quantity: json['quantity'] as int,
      averageCostPaise: json['averageCostPaise'] as int,
      lastUpdatedMillis: json['lastUpdatedMillis'] as int? ??
          DateTime.now().millisecondsSinceEpoch,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'symbol': symbol,
      'quantity': quantity,
      'averageCostPaise': averageCostPaise,
      'lastUpdatedMillis': lastUpdatedMillis,
    };
  }
}
