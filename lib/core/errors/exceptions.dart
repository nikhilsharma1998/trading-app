/// Exception thrown when local storage operations fail.
class StorageException implements Exception {
  final String message;
  const StorageException([this.message = 'Storage operation failed']);

  @override
  String toString() => 'StorageException: $message';
}

/// Exception thrown when domain validation rules are violated.
class ValidationException implements Exception {
  final String message;
  const ValidationException(this.message);

  @override
  String toString() => 'ValidationException: $message';
}

/// Exception thrown when trade execution encounters an illegal state.
class TradeExecutionException implements Exception {
  final String message;
  const TradeExecutionException(this.message);

  @override
  String toString() => 'TradeExecutionException: $message';
}
