import '../money/money.dart';

abstract class Failure {
  final String message;
  const Failure(this.message);

  @override
  String toString() => message;
}

class InsufficientBalanceFailure extends Failure {
  final Money available;
  final Money required;

  InsufficientBalanceFailure({
    required this.available,
    required this.required,
  }) : super(
          'Insufficient balance. Available: ${available.format()}, Required: ${required.format()}',
        );
}

class InsufficientHoldingsFailure extends Failure {
  final int availableQty;
  final int requestedQty;

  InsufficientHoldingsFailure({
    required this.availableQty,
    required this.requestedQty,
  }) : super(
          'Insufficient holdings. You can sell a maximum of $availableQty shares.',
        );
}

class InvalidQuantityFailure extends Failure {
  const InvalidQuantityFailure([super.message = 'Please enter a valid positive quantity']);
}

class DuplicateWatchlistStockFailure extends Failure {
  final String symbol;

  DuplicateWatchlistStockFailure(this.symbol)
      : super('$symbol is already in this watchlist.');
}

class StorageFailure extends Failure {
  const StorageFailure([super.message = 'Storage failure occurred']);
}
