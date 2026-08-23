import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/repositories/repository_providers.dart';

import '../../../holdings/domain/entities/holding.dart';
import '../../../holdings/domain/repositories/holding_repository.dart';
import '../../domain/entities/wallet.dart';
import '../../domain/repositories/wallet_repository.dart';

class WalletNotifier extends StateNotifier<AsyncValue<Wallet>> {
  final WalletRepository _repository;

  WalletNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadWallet();
  }

  Future<void> loadWallet() async {
    try {
      state = const AsyncValue.loading();
      final wallet = await _repository.getWallet();
      state = AsyncValue.data(wallet);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void updateWallet(Wallet wallet) {
    state = AsyncValue.data(wallet);
  }
}

final walletProvider =
    StateNotifierProvider<WalletNotifier, AsyncValue<Wallet>>((ref) {
  final repository = ref.watch(walletRepositoryProvider);
  return WalletNotifier(repository);
});

class HoldingsNotifier extends StateNotifier<AsyncValue<Map<String, Holding>>> {
  final HoldingRepository _repository;

  HoldingsNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadHoldings();
  }

  Future<void> loadHoldings() async {
    try {
      state = const AsyncValue.loading();
      final holdings = await _repository.getHoldings();
      state = AsyncValue.data(holdings);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void updateHoldings(Map<String, Holding> holdings) {
    state = AsyncValue.data(holdings);
  }
}

final holdingsMapProvider =
    StateNotifierProvider<HoldingsNotifier, AsyncValue<Map<String, Holding>>>((ref) {
  final repository = ref.watch(holdingRepositoryProvider);
  return HoldingsNotifier(repository);
});

/// Family provider returning available quantity held for a given stock symbol
final stockHoldingQtyProvider = Provider.family<int, String>((ref, symbol) {
  final holdingsAsync = ref.watch(holdingsMapProvider);
  return holdingsAsync.when(
    data: (holdings) => holdings[symbol]?.quantity ?? 0,
    loading: () => 0,
    error: (err, st) => 0,
  );
});
