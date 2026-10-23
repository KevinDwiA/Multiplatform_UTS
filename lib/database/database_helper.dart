import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/category.dart';
import '../models/transaction_item.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  static Future<Database>? _opening;

  static String databaseName = 'dompetku.db';
  static const int databaseVersion = 1;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _opening ??= _initDB(databaseName);
    try {
      _database = await _opening!;
      return _database!;
    } finally {
      _opening = null;
    }
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: databaseVersion,
      onCreate: _createDB,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // Tabel Kategori
    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        icon TEXT NOT NULL,
        color INTEGER NOT NULL
      )
    ''');

    // Tabel Transaksi
    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category_id INTEGER NOT NULL,
        type TEXT NOT NULL,
        amount REAL NOT NULL,
        transaction_date TEXT NOT NULL,
        description TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE RESTRICT
      )
    ''');

    // Index untuk optimasi query transaksi berdasarkan tanggal
    await db.execute('''
      CREATE INDEX idx_transactions_date ON transactions (transaction_date DESC)
    ''');

    // Seed kategori awal
    await _seedInitialCategories(db);
  }

  Future<void> _seedInitialCategories(Database db) async {
    final initialCategories = [
      {'name': 'Gaji', 'type': 'income', 'icon': 'payments', 'color': 0xFF2E7D32},
      {'name': 'Bonus & Hadiah', 'type': 'income', 'icon': 'card_giftcard', 'color': 0xFF1976D2},
      {'name': 'Investasi', 'type': 'income', 'icon': 'trending_up', 'color': 0xFF00796B},
      {'name': 'Penjualan', 'type': 'income', 'icon': 'store', 'color': 0xFFF57C00},
      {'name': 'Makanan & Minuman', 'type': 'expense', 'icon': 'restaurant', 'color': 0xFFE64A19},
      {'name': 'Transportasi', 'type': 'expense', 'icon': 'directions_car', 'color': 0xFF0288D1},
      {'name': 'Pendidikan', 'type': 'expense', 'icon': 'school', 'color': 0xFF512DA8},
      {'name': 'Belanja Harian', 'type': 'expense', 'icon': 'shopping_cart', 'color': 0xFFC2185B},
      {'name': 'Hiburan & Hobi', 'type': 'expense', 'icon': 'sports_esports', 'color': 0xFF7B1FA2},
      {'name': 'Kesehatan', 'type': 'expense', 'icon': 'medical_services', 'color': 0xFFD32F2F},
      {'name': 'Tagihan & Utilitas', 'type': 'expense', 'icon': 'receipt_long', 'color': 0xFF455A64},
      {'name': 'Lainnya', 'type': 'expense', 'icon': 'more_horiz', 'color': 0xFF616161},
    ];

    for (var cat in initialCategories) {
      await db.insert('categories', cat);
    }
  }

  // ===================== OPERASI KATEGORI =====================

  Future<List<Category>> getCategories({String? type}) async {
    final db = await database;
    List<Map<String, dynamic>> maps;
    if (type != null) {
      maps = await db.query(
        'categories',
        where: 'type = ?',
        whereArgs: [type],
        orderBy: 'id ASC',
      );
    } else {
      maps = await db.query('categories', orderBy: 'id ASC');
    }
    return maps.map((m) => Category.fromMap(m)).toList();
  }

  Future<Category?> getCategoryById(int id) async {
    final db = await database;
    final maps = await db.query(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return Category.fromMap(maps.first);
    }
    return null;
  }

  // ===================== OPERASI TRANSAKSI =====================

  Future<void> _validateTransaction(TransactionItem transaction) async {
    if (!transaction.amount.isFinite || transaction.amount <= 0) {
      throw ArgumentError('Nominal transaksi harus terbatas dan lebih besar dari 0');
    }
    if (transaction.type != 'income' && transaction.type != 'expense') {
      throw ArgumentError('Tipe transaksi tidak valid');
    }
    final category = await getCategoryById(transaction.categoryId);
    if (category == null || category.type != transaction.type) {
      throw ArgumentError('Kategori harus sesuai dengan tipe transaksi');
    }
  }

  Future<int> insertTransaction(TransactionItem transaction) async {
    await _validateTransaction(transaction);
    final db = await database;
    return await db.insert('transactions', transaction.toMap());
  }

  Future<int> updateTransaction(TransactionItem transaction) async {
    if (transaction.id == null) throw ArgumentError('ID transaksi diperlukan');
    await _validateTransaction(transaction);
    final db = await database;
    return await db.update(
      'transactions',
      transaction.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  Future<int> deleteTransaction(int id) async {
    final db = await database;
    return await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<TransactionItem>> getAllTransactions({
    String? type,
    String? monthPrefix, // Format: YYYY-MM
    int? categoryId,
    int? limit,
  }) async {
    final db = await database;
    final whereClauses = <String>[];
    final whereArgs = <dynamic>[];

    if (type != null && (type == 'income' || type == 'expense')) {
      whereClauses.add('t.type = ?');
      whereArgs.add(type);
    }

    if (monthPrefix != null && monthPrefix.isNotEmpty) {
      whereClauses.add('t.transaction_date LIKE ?');
      whereArgs.add('$monthPrefix%');
    }

    if (categoryId != null) {
      whereClauses.add('t.category_id = ?');
      whereArgs.add(categoryId);
    }

    final whereString = whereClauses.isNotEmpty ? 'WHERE ${whereClauses.join(' AND ')}' : '';
    final limitString = limit != null ? 'LIMIT $limit' : '';

    final query = '''
      SELECT 
        t.id,
        t.category_id,
        t.type,
        t.amount,
        t.transaction_date,
        t.description,
        t.created_at,
        c.name AS category_name,
        c.icon AS category_icon,
        c.color AS category_color
      FROM transactions t
      JOIN categories c ON t.category_id = c.id
      $whereString
      ORDER BY t.transaction_date DESC, t.id DESC
      $limitString
    ''';

    final maps = await db.rawQuery(query, whereArgs);
    return maps.map((m) => TransactionItem.fromMap(m)).toList();
  }

  // Perhitungan ringkasan keuangan
  Future<Map<String, double>> getFinancialSummary({String? monthPrefix}) async {
    final db = await database;
    
    // Total keseluruhan
    final allTotalsQuery = '''
      SELECT 
        COALESCE(SUM(CASE WHEN type = 'income' THEN amount ELSE 0 END), 0) AS total_income,
        COALESCE(SUM(CASE WHEN type = 'expense' THEN amount ELSE 0 END), 0) AS total_expense
      FROM transactions
    ''';
    final allTotals = await db.rawQuery(allTotalsQuery);
    final totalIncome = (allTotals.first['total_income'] as num).toDouble();
    final totalExpense = (allTotals.first['total_expense'] as num).toDouble();
    final currentBalance = totalIncome - totalExpense;

    // Total bulan berjalan atau bulan terpilih
    double monthlyIncome = totalIncome;
    double monthlyExpense = totalExpense;

    if (monthPrefix != null && monthPrefix.isNotEmpty) {
      final monthlyQuery = '''
        SELECT 
          COALESCE(SUM(CASE WHEN type = 'income' THEN amount ELSE 0 END), 0) AS month_income,
          COALESCE(SUM(CASE WHEN type = 'expense' THEN amount ELSE 0 END), 0) AS month_expense
        FROM transactions
        WHERE transaction_date LIKE ?
      ''';
      final monthlyTotals = await db.rawQuery(monthlyQuery, ['$monthPrefix%']);
      monthlyIncome = (monthlyTotals.first['month_income'] as num).toDouble();
      monthlyExpense = (monthlyTotals.first['month_expense'] as num).toDouble();
    }

    return {
      'currentBalance': currentBalance,
      'totalIncome': totalIncome,
      'totalExpense': totalExpense,
      'monthlyIncome': monthlyIncome,
      'monthlyExpense': monthlyExpense,
    };
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
