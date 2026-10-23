import 'package:shared_preferences/shared_preferences.dart';

class BudgetPreferenceService {
  static const String keyMonthlyBudget = 'dompetku_monthly_budget';

  static Future<double> getMonthlyBudget() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(keyMonthlyBudget) ?? 0.0;
  }

  static Future<bool> setMonthlyBudget(double amount) async {
    if (!amount.isFinite || amount < 0) {
      throw ArgumentError('Anggaran harus angka terbatas dan tidak negatif');
    }
    final prefs = await SharedPreferences.getInstance();
    return await prefs.setDouble(keyMonthlyBudget, amount);
  }

  static Future<bool> clearMonthlyBudget() async {
    final prefs = await SharedPreferences.getInstance();
    return await prefs.remove(keyMonthlyBudget);
  }
}
