import 'package:intl/intl.dart';
import '../models/currency.dart';

final dateFormat = DateFormat('d MMM yyyy', 'ar');
final dateTimeFormat = DateFormat('d MMM yyyy - h:mm a', 'ar');
final timeFormat = DateFormat('h:mm a', 'ar');

NumberFormat _amountFormat(AppCurrency currency) {
  if (currency.code == 'SYP' || currency.code == 'IQD' || currency.code == 'LBP') {
    return NumberFormat('#,##0', 'ar');
  }
  return NumberFormat('#,##0.00', 'ar');
}

String formatCurrency(double amount, AppCurrency currency) {
  final formatted = _amountFormat(currency).format(amount);
  if (currency.symbol == '\$' || currency.symbol == '€' || currency.symbol == '£' || currency.symbol == '₺') {
    return '$formatted ${currency.symbol}';
  }
  return '$formatted ${currency.symbol}';
}

String formatDate(DateTime date) => dateFormat.format(date);

String formatDateTime(DateTime date) => dateTimeFormat.format(date);

String formatTime(DateTime date) => timeFormat.format(date);
