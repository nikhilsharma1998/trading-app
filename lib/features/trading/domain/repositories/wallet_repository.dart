import '../entities/wallet.dart';

abstract class WalletRepository {
  /// Loads persisted wallet or initializes with default ₹1,00,000 if not found
  Future<Wallet> getWallet();

  /// Persists new wallet state
  Future<void> saveWallet(Wallet wallet);
}
