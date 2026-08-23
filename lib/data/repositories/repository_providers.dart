import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/holdings/domain/repositories/holding_repository.dart';
import '../../features/trading/domain/repositories/order_repository.dart';
import '../../features/trading/domain/repositories/wallet_repository.dart';
import '../../features/watchlist/domain/repositories/watchlist_repository.dart';
import '../local/local_storage_service.dart';
import 'holding_repository_impl.dart';
import 'order_repository_impl.dart';
import 'wallet_repository_impl.dart';
import 'watchlist_repository_impl.dart';

/// Provider for the local storage service (defaults to HiveLocalStorageService)
final localStorageServiceProvider = Provider<LocalStorageService>((ref) {
  return HiveLocalStorageService();
});

/// Provider for WatchlistRepository
final watchlistRepositoryProvider = Provider<WatchlistRepository>((ref) {
  final storage = ref.watch(localStorageServiceProvider);
  return WatchlistRepositoryImpl(storage);
});

/// Provider for WalletRepository
final walletRepositoryProvider = Provider<WalletRepository>((ref) {
  final storage = ref.watch(localStorageServiceProvider);
  return WalletRepositoryImpl(storage);
});

/// Provider for HoldingRepository
final holdingRepositoryProvider = Provider<HoldingRepository>((ref) {
  final storage = ref.watch(localStorageServiceProvider);
  return HoldingRepositoryImpl(storage);
});

/// Provider for OrderRepository
final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  final storage = ref.watch(localStorageServiceProvider);
  return OrderRepositoryImpl(storage);
});
