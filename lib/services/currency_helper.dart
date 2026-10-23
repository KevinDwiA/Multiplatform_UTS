import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CurrencyHelper {
  static final NumberFormat _currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  static String formatRupiah(double amount) {
    return _currencyFormatter.format(amount);
  }

  static String formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('d MMMM yyyy', 'id_ID').format(date);
    } catch (_) {
      return dateString;
    }
  }

  static String formatShortDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('d MMM', 'id_ID').format(date);
    } catch (_) {
      return dateString;
    }
  }

  static IconData getCategoryIconData(String iconName) {
    switch (iconName) {
      case 'payments':
        return Icons.payments;
      case 'card_giftcard':
        return Icons.card_giftcard;
      case 'trending_up':
        return Icons.trending_up;
      case 'store':
        return Icons.store;
      case 'restaurant':
        return Icons.restaurant;
      case 'directions_car':
        return Icons.directions_car;
      case 'school':
        return Icons.school;
      case 'shopping_cart':
        return Icons.shopping_cart;
      case 'sports_esports':
        return Icons.sports_esports;
      case 'medical_services':
        return Icons.medical_services;
      case 'receipt_long':
        return Icons.receipt_long;
      case 'more_horiz':
      default:
        return Icons.category;
    }
  }
}
