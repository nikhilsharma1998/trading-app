import '../../core/constants/stock_constants.dart';
import '../../core/money/money.dart';
import '../../features/trading/domain/entities/wallet.dart';
import '../../features/trading/domain/repositories/wallet_repository.dart';
import '../local/local_storage_keys.dart';
import '../local/local_storage_service.dart';

class WalletRepositoryImpl implements WalletRepository {
  final LocalStorageService _storageService;

  WalletRepositoryImpl(this._storageService);

  @override
  Future<Wallet> getWallet() async {
    final raw = _storageService.get(LocalStorageKeys.walletBalancePaiseKey);
    if (raw == null) {
      // First launch: initialize default ₹1,00,000 balance
      const initialWallet = Wallet(balance: StockConstants.initialWalletBalance);
      await saveWallet(initialWallet);
      return initialWallet;
    }

    if (raw is int) {
      return Wallet(balance: Money(raw));
    } else if (raw is num) {
      return Wallet(balance: Money(raw.toInt()));
    } else if (raw is String) {
      final parsed = int.tryParse(raw);
      if (parsed != null) return Wallet(balance: Money(parsed));
    }

    return const Wallet(balance: StockConstants.initialWalletBalance);
  }

  @override
  Future<void> saveWallet(Wallet wallet) async {
    await _storageService.put(
      LocalStorageKeys.walletBalancePaiseKey,
      wallet.balance.paise,
    );
  }
}
