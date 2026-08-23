import '../../../../core/money/money.dart';
import '../../domain/entities/wallet.dart';

class WalletModel {
  final int balancePaise;

  const WalletModel({required this.balancePaise});

  factory WalletModel.fromDomain(Wallet wallet) {
    return WalletModel(balancePaise: wallet.balance.paise);
  }

  Wallet toDomain() {
    return Wallet(balance: Money(balancePaise));
  }

  factory WalletModel.fromJson(Map<String, dynamic> json) {
    return WalletModel(
      balancePaise: json['balancePaise'] as int? ?? 10000000,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'balancePaise': balancePaise,
    };
  }
}
