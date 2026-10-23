import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'database/database_helper.dart';
import 'models/category.dart';
import 'models/transaction_item.dart';
import 'screens/transaction_form_screen.dart';
import 'services/budget_preference_service.dart';
import 'services/currency_helper.dart';
import 'services/theme_preference_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID');
  bool dark = false;
  try {
    dark = await ThemePreferenceService.isDarkMode();
  } catch (e) {
    debugPrint('Preferensi tema gagal dimuat: $e');
  }
  runApp(DompetKuApp(initialDarkMode: dark));
}

class DompetKuApp extends StatefulWidget {
  final bool initialDarkMode;
  const DompetKuApp({super.key, required this.initialDarkMode});
  @override
  State<DompetKuApp> createState() => _DompetKuAppState();
}

class _DompetKuAppState extends State<DompetKuApp> {
  final messengerKey = GlobalKey<ScaffoldMessengerState>();
  late bool _dark = widget.initialDarkMode;

  Future<void> _setDark(bool value) async {
    try {
      final saved = await ThemePreferenceService.setDarkMode(value);
      if (!saved) throw StateError('Preferensi tidak tersimpan');
      if (mounted) setState(() => _dark = value);
    } catch (e) {
      messengerKey.currentState?.showSnackBar(SnackBar(content: Text('Gagal menyimpan tema: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      scaffoldMessengerKey: messengerKey,
      title: 'DompetKu',
      debugShowCheckedModeBanner: false,
      themeMode: _dark ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff146c94)),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xff56c8ff),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: DashboardScreen(isDark: _dark, onThemeChanged: _setDark),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  final bool isDark;
  final ValueChanged<bool> onThemeChanged;
  const DashboardScreen({
    super.key,
    required this.isDark,
    required this.onThemeChanged,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final db = DatabaseHelper.instance;
  bool loading = true;
  String? error;
  Map<String, double> summary = {};
  List<TransactionItem> latest = [];
  double budget = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() { loading = true; error = null; });
    try {
      final now = DateFormat('yyyy-MM').format(DateTime.now());
      final s = await db.getFinancialSummary(monthPrefix: now);
      final l = await db.getAllTransactions(limit: 5);
      final b = await BudgetPreferenceService.getMonthlyBudget();
      if (!mounted) return;
      setState(() {
        summary = s;
        latest = l;
        budget = b;
        loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          error = 'Data tidak dapat dimuat: $e';
          loading = false;
        });
      }
    }
  }

  Future<void> _openForm([TransactionItem? item]) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => TransactionFormScreen(existingTransaction: item),
      ),
    );
    if (changed == true) await _load();
  }

  Future<void> _budgetDialog() async {
    final c = TextEditingController(text: budget == 0 ? '' : budget.toInt().toString());
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        scrollable: true,
        title: const Text('Anggaran Bulanan'),
        content: TextField(
          controller: c,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Batas pengeluaran (Rp)'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    if (result == true) {
      final value = double.tryParse(c.text.trim());
      if (value == null || !value.isFinite || value < 0) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Anggaran harus angka tidak negatif')),
          );
        }
        return;
      }
      try {
        if (!await BudgetPreferenceService.setMonthlyBudget(value)) {
          throw StateError('Anggaran tidak tersimpan');
        }
        await _load();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal menyimpan: $e')),
          );
        }
      }
    }
    c.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final expense = summary['monthlyExpense'] ?? 0;
    final remaining = (budget - expense).clamp(0, double.infinity).toDouble();

    return Scaffold(
      appBar: AppBar(
        title: const Text('DompetKu'),
        actions: [
          IconButton(
            tooltip: 'Tema gelap',
            onPressed: () => widget.onThemeChanged(!widget.isDark),
            icon: Icon(widget.isDark ? Icons.light_mode : Icons.dark_mode),
          ),
          IconButton(
            tooltip: 'Atur anggaran',
            onPressed: _budgetDialog,
            icon: const Icon(Icons.savings),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add),
        label: const Text('Transaksi'),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : error != null
                ? ListView(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            Text(error!),
                            const SizedBox(height: 12),
                            FilledButton(
                              onPressed: _load,
                              child: const Text('Coba lagi'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : LayoutBuilder(
                    builder: (context, constraints) => ListView(
                      padding: EdgeInsets.all(constraints.maxWidth < 360 ? 12 : 16),
                      children: [
                        _BalanceCard(value: summary['currentBalance'] ?? 0),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            _MetricCard('Pemasukan bulan ini', summary['monthlyIncome'] ?? 0, Colors.green),
                            _MetricCard('Pengeluaran bulan ini', expense, Colors.red),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Anggaran bulan ini', style: TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                Text(
                                  budget == 0
                                      ? 'Belum diatur'
                                      : '${CurrencyHelper.formatRupiah(expense)} dari ${CurrencyHelper.formatRupiah(budget)}',
                                ),
                                if (budget > 0) ...[
                                  const SizedBox(height: 8),
                                  LinearProgressIndicator(value: (expense / budget).clamp(0, 1)),
                                  const SizedBox(height: 6),
                                  Text('Sisa: ${CurrencyHelper.formatRupiah(remaining)}'),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          children: [
                            const Text(
                              '5 transaksi terbaru',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            TextButton(
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => TransactionsScreen(onChanged: _load),
                                ),
                              ),
                              child: const Text('Lihat semua'),
                            ),
                          ],
                        ),
                        if (latest.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(24),
                            child: Center(child: Text('Belum ada transaksi.')),
                          )
                        else
                          ...latest.map((t) => _TransactionTile(item: t, onTap: () => _openForm(t))),
                        const SizedBox(height: 90),
                      ],
                    ),
                  ),
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final double value;
  const _BalanceCard({required this.value});
  @override
  Widget build(BuildContext c) => Card(
        color: Theme.of(c).colorScheme.primaryContainer,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Saldo saat ini'),
              const SizedBox(height: 6),
              Text(
                CurrencyHelper.formatRupiah(value),
                style: Theme.of(c).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      );
}

class _MetricCard extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  const _MetricCard(this.label, this.value, this.color);
  @override
  Widget build(BuildContext c) => SizedBox(
        width: (MediaQuery.sizeOf(c).width - 44) / 2,
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: color, fontSize: 12)),
                const SizedBox(height: 6),
                Text(
                  CurrencyHelper.formatRupiah(value),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      );
}

class _TransactionTile extends StatelessWidget {
  final TransactionItem item;
  final VoidCallback onTap;
  const _TransactionTile({required this.item, required this.onTap});
  @override
  Widget build(BuildContext c) => Card(
        child: ListTile(
          onTap: onTap,
          leading: CircleAvatar(
            child: Icon(item.type == 'income' ? Icons.arrow_downward : Icons.arrow_upward),
          ),
          title: Text(item.categoryName ?? 'Kategori'),
          subtitle: Text(
            '${CurrencyHelper.formatShortDate(item.transactionDate)}${item.description == null ? '' : ' • ${item.description}'}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Text(
            '${item.type == 'income' ? '+' : '-'}${CurrencyHelper.formatRupiah(item.amount)}',
            style: TextStyle(
              color: item.type == 'income' ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
}

class TransactionsScreen extends StatefulWidget {
  final Future<void> Function() onChanged;
  const TransactionsScreen({super.key, required this.onChanged});
  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final db = DatabaseHelper.instance;
  List<TransactionItem> items = [];
  List<Category> categories = [];
  bool loading = true;
  String? type;
  int? category;
  String month = DateFormat('yyyy-MM').format(DateTime.now());

  @override
  void initState() {
    super.initState();
    _load();
  }

  String? loadError;

  Future<void> _load() async {
    if (!mounted) return;
    setState(() { loading = true; loadError = null; });
    try {
      final t = await db.getAllTransactions(type: type, categoryId: category, monthPrefix: month);
      final c = await db.getCategories();
      if (mounted) {
        setState(() {
          items = t;
          categories = c;
          loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { loading = false; loadError = 'Gagal memuat: $e'; });
    }
  }

  Future<void> _edit(TransactionItem? t) async {
    final x = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => TransactionFormScreen(existingTransaction: t)),
    );
    if (x == true) {
      await _load();
      await widget.onChanged();
    }
  }

  Future<void> _delete(TransactionItem t) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Hapus transaksi?'),
        content: const Text('Transaksi yang dihapus tidak dapat dikembalikan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (yes == true && t.id != null) {
      try {
        await db.deleteTransaction(t.id!);
        await _load();
        await widget.onChanged();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal menghapus: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext c) => Scaffold(
        appBar: AppBar(title: const Text('Transaksi')),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _edit(null),
          child: const Icon(Icons.add),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  DropdownButton<String?>(
                    value: type,
                    hint: const Text('Semua tipe'),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('Semua tipe')),
                      DropdownMenuItem(value: 'income', child: Text('Pemasukan')),
                      DropdownMenuItem(value: 'expense', child: Text('Pengeluaran')),
                    ],
                    onChanged: (v) {
                      setState(() => type = v);
                      _load();
                    },
                  ),
                  DropdownButton<int?>(
                    value: category,
                    hint: const Text('Semua kategori'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Semua kategori')),
                      ...categories.map((x) => DropdownMenuItem(value: x.id, child: Text(x.name))),
                    ],
                    onChanged: (v) {
                      setState(() => category = v);
                      _load();
                    },
                  ),
                  TextButton(
                    onPressed: () async {
                      final picked = await showDatePicker(context: context,
                        initialDate: DateTime.parse('$month-01'),
                        firstDate: DateTime(2020), lastDate: DateTime(2035));
                      if (!mounted || picked == null) return;
                      setState(() => month = DateFormat('yyyy-MM').format(picked));
                      await _load();
                    },
                    child: Text(month),
                  ),
                ],
              ),
            ),
            Expanded(
              child: loading
                  ? const Center(child: CircularProgressIndicator())
                  : loadError != null
                      ? Center(child: FilledButton(onPressed: _load, child: Text(loadError!)))
                      : items.isEmpty
                          ? const Center(child: Text('Tidak ada transaksi untuk filter ini.'))
                          : ListView.builder(
                          itemCount: items.length,
                          itemBuilder: (_, i) => Dismissible(
                            key: ValueKey(items[i].id),
                            direction: DismissDirection.endToStart,
                            confirmDismiss: (_) => _delete(items[i]).then((_) => false),
                            background: Container(
                              color: Colors.red,
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              child: const Icon(Icons.delete, color: Colors.white),
                            ),
                            child: _TransactionTile(item: items[i], onTap: () => _edit(items[i])),
                          ),
                        ),
            ),
          ],
        ),
      );
}
