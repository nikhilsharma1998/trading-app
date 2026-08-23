import 'package:intl/intl.dart';
import '../money/money.dart';

class Formatters {
  Formatters._();

  /// Formats money values with currency symbol ₹
  static String formatCurrency(Money money, {bool includeSign = false}) {
    return money.format(includeSign: includeSign);
  }

  /// Formats percentage changes (e.g., +0.36%, -1.25%, 0.00%)
  static String formatPercentage(double percent, {bool includeSign = true}) {
    final formatted = percent.abs().toStringAsFixed(2);
    if (percent > 0 && includeSign) {
      return '+$formatted%';
    } else if (percent < 0) {
      return '-$formatted%';
    }
    return '$formatted%';
  }

  /// Formats date time for display in orders and tickets
  static String formatDateTime(DateTime dateTime) {
    return DateFormat('dd MMM yyyy, hh:mm a').format(dateTime);
  }

  /// Formats short time for tickers (e.g. 10:45:12 AM)
  static String formatTime(DateTime dateTime) {
    return DateFormat('hh:mm:ss a').format(dateTime);
  }

  /// Formats stock quantities
  static String formatQuantity(int quantity) {
    return NumberFormat.decimalPattern('en_IN').format(quantity);
  }
}
