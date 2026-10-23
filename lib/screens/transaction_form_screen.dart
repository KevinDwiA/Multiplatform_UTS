import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/category.dart';
import '../models/transaction_item.dart';
import '../services/currency_helper.dart';

class TransactionFormScreen extends StatefulWidget {
  final TransactionItem? existingTransaction;

  const TransactionFormScreen({super.key, this.existingTransaction});

  @override
  State<TransactionFormScreen> createState() => _TransactionFormScreenState();
}

class _TransactionFormScreenState extends State<TransactionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descController = TextEditingController();

  String _type = 'expense'; // 'income' or 'expense'
  DateTime _selectedDate = DateTime.now();
  int? _selectedCategoryId;
  List<Category> _categories = [];
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingTransaction != null) {
      final t = widget.existingTransaction!;
      _type = t.type;
      _amountController.text = t.amount.toInt().toString();
      _descController.text = t.description ?? '';
      _selectedCategoryId = t.categoryId;
      try {
        _selectedDate = DateTime.parse(t.transactionDate);
      } catch (_) {
        _selectedDate = DateTime.now();
      }
    }
    _loadCategories();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoading = true);
    try {
      final cats = await DatabaseHelper.instance.getCategories(type: _type);
      if (!mounted) return;
      setState(() {
        _categories = cats;
        if (_selectedCategoryId == null || !cats.any((c) => c.id == _selectedCategoryId)) {
          _selectedCategoryId = cats.isNotEmpty ? cats.first.id : null;
        }
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat kategori: $e')),
      );
    }
  }

  void _onTypeChanged(String newType) {
    if (_type != newType) {
      setState(() {
        _type = newType;
        _selectedCategoryId = null;
      });
      _loadCategories();
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (mounted && picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan pilih kategori terlebih dahulu')),
      );
      return;
    }

    final matchedCategory = _categories.any((c) => c.id == _selectedCategoryId && c.type == _type);
    if (!matchedCategory) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kategori tidak sesuai dengan tipe transaksi')),
      );
      return;
    }

    final amountText = _amountController.text.trim();
    final amount = double.tryParse(amountText);
    if (amount == null || !amount.isFinite || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nominal harus berupa angka valid dan lebih besar dari 0')),
      );
      return;
    }

    setState(() => _isSaving = true);
    final dateString = DateFormat('yyyy-MM-dd').format(_selectedDate);

    final item = TransactionItem(
      id: widget.existingTransaction?.id,
      categoryId: _selectedCategoryId!,
      type: _type,
      amount: amount,
      transactionDate: dateString,
      description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
      createdAt: widget.existingTransaction?.createdAt,
    );

    try {
      if (widget.existingTransaction == null) {
        await DatabaseHelper.instance.insertTransaction(item);
      } else {
        await DatabaseHelper.instance.updateTransaction(item);
      }

      if (mounted) {
        setState(() => _isSaving = false);
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan transaksi: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existingTransaction != null;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Transaksi' : 'Tambah Transaksi'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 16,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Tipe Selector (Pemasukan vs Pengeluaran)
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.arrow_downward, size: 18),
                              label: const Text('Pengeluaran'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _type == 'expense' ? Colors.red.shade600 : Colors.grey.shade300,
                                foregroundColor: _type == 'expense' ? Colors.white : Colors.black87,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              onPressed: () => _onTypeChanged('expense'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.arrow_upward, size: 18),
                              label: const Text('Pemasukan'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _type == 'income' ? Colors.green.shade600 : Colors.grey.shade300,
                                foregroundColor: _type == 'income' ? Colors.white : Colors.black87,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              onPressed: () => _onTypeChanged('income'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Input Nominal
                      TextFormField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: InputDecoration(
                          labelText: 'Nominal (Rp) *',
                          hintText: 'Contoh: 50000',
                          prefixIcon: const Icon(Icons.attach_money),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Nominal wajib diisi';
                          }
                          final numVal = double.tryParse(val.trim());
                          if (numVal == null || !numVal.isFinite || numVal <= 0) {
                            return 'Nominal harus angka valid lebih besar dari 0';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Pemilihan Kategori
                      DropdownButtonFormField<int>(
                        key: ValueKey(_type),
                        initialValue: _selectedCategoryId,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: 'Kategori *',
                          prefixIcon: const Icon(Icons.category),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        items: _categories.map((c) {
                          return DropdownMenuItem<int>(
                            value: c.id,
                            child: Row(
                              children: [
                                Icon(CurrencyHelper.getCategoryIconData(c.icon), color: Color(c.color), size: 20),
                                const SizedBox(width: 8),
                                Expanded(child: Text(c.name, overflow: TextOverflow.ellipsis)),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedCategoryId = val;
                          });
                        },
                        validator: (val) => val == null ? 'Kategori wajib dipilih' : null,
                      ),
                      const SizedBox(height: 16),

                      // Tanggal Transaksi
                      InkWell(
                        onTap: _pickDate,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                          decoration: BoxDecoration(
                            border: Border.all(color: theme.dividerColor),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(_selectedDate),
                                  style: const TextStyle(fontSize: 15),
                                ),
                              ),
                              const Icon(Icons.arrow_drop_down),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Catatan / Deskripsi
                      TextFormField(
                        controller: _descController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: 'Catatan / Keterangan (Opsional)',
                          hintText: 'Contoh: Makan siang nasi padang',
                          prefixIcon: const Icon(Icons.notes),
                          alignLabelWithHint: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Tombol Simpan
                      ElevatedButton(
                        onPressed: _isSaving ? null : _saveTransaction,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(
                                isEdit ? 'Perbarui Transaksi' : 'Simpan Transaksi',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
