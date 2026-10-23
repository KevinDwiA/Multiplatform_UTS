import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dompetku_uts/services/budget_preference_service.dart';
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test('budget rejects negative and non finite amounts', () async {
    for (final amount in [-1.0, double.nan, double.infinity]) {
      await expectLater(BudgetPreferenceService.setMonthlyBudget(amount), throwsArgumentError);
    }
  });
  test('budget saves reads clears', () async {
    expect(await BudgetPreferenceService.setMonthlyBudget(1500000), isTrue);
    expect(await BudgetPreferenceService.getMonthlyBudget(), 1500000);
    expect(await BudgetPreferenceService.clearMonthlyBudget(), isTrue);
    expect(await BudgetPreferenceService.getMonthlyBudget(), 0);
  });
}
