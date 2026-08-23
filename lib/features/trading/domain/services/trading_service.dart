import 'package:uuid/uuid.dart';
import '../../../../core/errors/failures.dart';
import '../../../holdings/domain/entities/holding.dart';
import '../../../holdings/domain/repositories/holding_repository.dart';
import '../../../market/domain/repositories/market_repository.dart';
import '../entities/order.dart';
import '../entities/trade_execution_result.dart';
import '../repositories/order_repository.dart';
import '../repositories/wallet_repository.dart';


class TradingService {
  final MarketRepository marketRepository;
  final WalletRepository walletRepository;
  final HoldingRepository holdingRepository;
  final OrderRepository orderRepository;

  TradingService({
    required this.marketRepository,
    required this.walletRepository,
    required this.holdingRepository,
    required this.orderRepository,
  });

  /// Executes an atomic trade transaction at the immediate latest LTP
  Future<TradeExecutionResult> executeTrade({
    required String symbol,
    required OrderSide side,
    required int quantity,
  }) async {
    if (quantity <= 0) {
      throw const InvalidQuantityFailure('Quantity must be greater than zero');
    }

    // 1. Get the latest LTP from the centralized market price store at execution time
    final latestLtp = marketRepository.getLatestPrice(symbol);
    if (latestLtp.paise <= 0) {
      throw const InvalidQuantityFailure('Invalid market price for execution');
    }

    // 2. Calculate exact order value in minor units (paise)
    final orderValue = latestLtp * quantity;

    // 3. Load latest user financial state
    final currentWallet = await walletRepository.getWallet();
    final currentHolding = await holdingRepository.getHoldingBySymbol(symbol);

    final now = DateTime.now();
    final orderId = const Uuid().v4();

    if (side == OrderSide.buy) {
      // Validate Buy balance
      if (orderValue > currentWallet.balance) {
        throw InsufficientBalanceFailure(
          available: currentWallet.balance,
          required: orderValue,
        );
      }

      // Deduct funds from wallet
      final updatedWallet = currentWallet.deduct(orderValue);
      await walletRepository.saveWallet(updatedWallet);

      // Create or update holding with weighted average cost
      final Holding updatedHolding;
      if (currentHolding == null) {
        updatedHolding = Holding(
          symbol: symbol,
          quantity: quantity,
          averageCost: latestLtp,
          lastUpdated: now,
        );
      } else {
        updatedHolding = currentHolding.addShares(quantity, latestLtp);
      }
      await holdingRepository.saveHolding(updatedHolding);

      // Create and persist order record
      final order = Order(
        id: orderId,
        symbol: symbol,
        side: OrderSide.buy,
        quantity: quantity,
        price: latestLtp,
        totalValue: orderValue,
        timestamp: now,
        status: OrderStatus.completed,
      );
      await orderRepository.saveOrder(order);

      return TradeExecutionResult(
        order: order,
        remainingBalance: updatedWallet.balance,
        remainingHoldingQty: updatedHolding.quantity,
      );
    } else {
      // Validate Sell holding quantity
      final availableQty = currentHolding?.quantity ?? 0;
      if (availableQty < quantity) {
        throw InsufficientHoldingsFailure(
          availableQty: availableQty,
          requestedQty: quantity,
        );
      }

      // Credit funds to wallet
      final updatedWallet = currentWallet.add(orderValue);
      await walletRepository.saveWallet(updatedWallet);

      // Reduce or remove holding
      final reducedHolding = currentHolding!.reduceShares(quantity);
      if (reducedHolding == null) {
        await holdingRepository.removeHolding(symbol);
      } else {
        await holdingRepository.saveHolding(reducedHolding);
      }

      // Create and persist order record
      final order = Order(
        id: orderId,
        symbol: symbol,
        side: OrderSide.sell,
        quantity: quantity,
        price: latestLtp,
        totalValue: orderValue,
        timestamp: now,
        status: OrderStatus.completed,
      );
      await orderRepository.saveOrder(order);

      return TradeExecutionResult(
        order: order,
        remainingBalance: updatedWallet.balance,
        remainingHoldingQty: reducedHolding?.quantity ?? 0,
      );
    }
  }
}
