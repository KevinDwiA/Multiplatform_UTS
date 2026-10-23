// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:dompetku_uts/main.dart';
import 'package:dompetku_uts/database/database_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  DatabaseHelper.databaseName = 'test_widget.db';
  setUpAll(() async {
    await initializeDateFormatting('id_ID');
  });
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final db = await DatabaseHelper.instance.database;
    await db.delete('transactions');
  });
  tearDownAll(() async => DatabaseHelper.instance.close());

  for (final size in [const Size(320, 568), const Size(412, 915)]) {
    testWidgets('dashboard responsive at ${size.width}', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(const DompetKuApp(initialDarkMode: false));
      for (int i = 0; i < 5; i++) {
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(find.text('DompetKu'), findsOneWidget);
      expect(find.text('Saldo saat ini'), findsOneWidget);
      final err = tester.takeException();
      if (err is FlutterError) {
        // ignore: avoid_print
        print('ERR_DETAILS: ${err.toStringDeep()}');
      }
      expect(err, isNull);
    });
  }

  testWidgets('dark theme and transaction form open', (tester) async {
    await tester.pumpWidget(const DompetKuApp(initialDarkMode: true));
    for (int i = 0; i < 5; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
        await tester.pump(const Duration(milliseconds: 100));
    }
    expect(tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode, ThemeMode.dark);
    await tester.tap(find.text('Transaksi'));
    for (int i = 0; i < 5; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
        await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('Tambah Transaksi'), findsOneWidget);
    expect(find.text('Nominal (Rp) *'), findsOneWidget);
  });
}
