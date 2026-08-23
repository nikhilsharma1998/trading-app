import '../../../../core/money/money.dart';
import 'order.dart';

class TradeExecutionResult {
  final Order order;
  final Money remainingBalance;
  final int remainingHoldingQty;

  const TradeExecutionResult({
    required this.order,
    required this.remainingBalance,
    required this.remainingHoldingQty,
  });
}
