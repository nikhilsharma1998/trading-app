import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/repositories/repository_providers.dart';
import '../../../market/presentation/providers/market_feed_provider.dart';
import '../../domain/entities/order.dart';
import '../../domain/entities/trade_execution_result.dart';
import '../../domain/repositories/order_repository.dart';
import '../../domain/services/trading_service.dart';
import 'wallet_provider.dart';

final tradingServiceProvider = Provider<TradingService>((ref) {
  final marketRepo = ref.watch(marketRepositoryProvider);
  final walletRepo = ref.watch(walletRepositoryProvider);
  final holdingRepo = ref.watch(holdingRepositoryProvider);
  final orderRepo = ref.watch(orderRepositoryProvider);

  return TradingService(
    marketRepository: marketRepo,
    walletRepository: walletRepo,
    holdingRepository: holdingRepo,
    orderRepository: orderRepo,
  );
});

class OrderHistoryNotifier extends StateNotifier<AsyncValue<List<Order>>> {
  final OrderRepository _repository;

  OrderHistoryNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadOrders();
  }

  Future<void> loadOrders() async {
    try {
      state = const AsyncValue.loading();
      final orders = await _repository.getOrders();
      state = AsyncValue.data(orders);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void addOrder(Order order) {
    final current = state.value ?? [];
    state = AsyncValue.data([order, ...current]);
  }
}

final orderHistoryProvider =
    StateNotifierProvider<OrderHistoryNotifier, AsyncValue<List<Order>>>((ref) {
  final repository = ref.watch(orderRepositoryProvider);
  return OrderHistoryNotifier(repository);
});

class TradingController extends StateNotifier<AsyncValue<TradeExecutionResult?>> {
  final TradingService _tradingService;
  final Ref _ref;

  TradingController(this._tradingService, this._ref)
      : super(const AsyncValue.data(null));

  Future<TradeExecutionResult?> submitOrder({
    required String symbol,
    required OrderSide side,
    required int quantity,
  }) async {
    try {
      state = const AsyncValue.loading();
      final result = await _tradingService.executeTrade(
        symbol: symbol,
        side: side,
        quantity: quantity,
      );

      // Refresh synchronized state
      _ref.read(walletProvider.notifier).loadWallet();
      _ref.read(holdingsMapProvider.notifier).loadHoldings();
      _ref.read(orderHistoryProvider.notifier).addOrder(result.order);

      state = AsyncValue.data(result);
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  void reset() {
    state = const AsyncValue.data(null);
  }
}

final tradingControllerProvider =
    StateNotifierProvider<TradingController, AsyncValue<TradeExecutionResult?>>((ref) {
  final tradingService = ref.watch(tradingServiceProvider);
  return TradingController(tradingService, ref);
});
