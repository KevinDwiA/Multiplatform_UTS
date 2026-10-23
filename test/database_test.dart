import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:dompetku_uts/database/database_helper.dart';
import 'package:dompetku_uts/models/transaction_item.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  DatabaseHelper.databaseName = 'test_database.db';
  final helper = DatabaseHelper.instance;
  setUp(() async {
    final db = await helper.database;
    await db.delete('transactions');
  });

  tearDownAll(() async => helper.close());
  TransactionItem item({double amount=100, int category=1, String type='income', String date='2026-10-01'}) => TransactionItem(categoryId:category,type:type,amount:amount,transactionDate:date);
  test('rejects invalid amounts and category type', () async {
    for(final amount in [-1.0,0.0,double.infinity,double.nan]) {
      await expectLater(helper.insertTransaction(item(amount:amount)),throwsArgumentError);
    }
    await expectLater(helper.insertTransaction(item(category:5)),throwsArgumentError);
  });
  test('real SQLite CRUD aggregates filters and FK RESTRICT', () async {
    final first = item(amount:1000,date:'2026-09-01');
    final id=await helper.insertTransaction(first);
    final expenseId=await helper.insertTransaction(item(amount:250,category:5,type:'expense'));
    expect((await helper.getFinancialSummary(monthPrefix:'2026-10'))['currentBalance'],750);
    expect((await helper.getFinancialSummary(monthPrefix:'2026-10'))['monthlyIncome'],0);
    expect((await helper.getFinancialSummary(monthPrefix:'2026-10'))['monthlyExpense'],250);
    expect((await helper.getAllTransactions(type:'income',monthPrefix:'2026-10')).length,0);
    expect((await helper.getAllTransactions(categoryId:5)).length,1);
    await helper.updateTransaction(first.copyWith(id:id,amount:1200));
    expect((await helper.getAllTransactions(type:'income')).single.createdAt,first.createdAt);
    final db=await helper.database;
    await expectLater(db.delete('categories',where:'id = ?',whereArgs:[1]),throwsA(isA<DatabaseException>()));
    await helper.deleteTransaction(expenseId);
    expect((await helper.getFinancialSummary())['currentBalance'],1200);
  });
}
