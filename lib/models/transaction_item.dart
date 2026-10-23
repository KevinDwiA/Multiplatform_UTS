class TransactionItem {
  final int? id;
  final int categoryId;
  final String type; // 'income' or 'expense'
  final double amount;
  final String transactionDate; // YYYY-MM-DD
  final String? description;
  final String createdAt;

  // Joined fields for display convenience
  final String? categoryName;
  final String? categoryIcon;
  final int? categoryColor;

  TransactionItem({
    this.id,
    required this.categoryId,
    required this.type,
    required this.amount,
    required this.transactionDate,
    this.description,
    String? createdAt,
    this.categoryName,
    this.categoryIcon,
    this.categoryColor,
  }) : createdAt = createdAt ?? DateTime.now().toIso8601String();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category_id': categoryId,
      'type': type,
      'amount': amount,
      'transaction_date': transactionDate,
      'description': description,
      'created_at': createdAt,
    };
  }

  factory TransactionItem.fromMap(Map<String, dynamic> map) {
    return TransactionItem(
      id: map['id'] as int?,
      categoryId: map['category_id'] as int,
      type: map['type'] as String,
      amount: (map['amount'] as num).toDouble(),
      transactionDate: map['transaction_date'] as String,
      description: map['description'] as String?,
      createdAt: map['created_at'] as String? ?? DateTime.now().toIso8601String(),
      categoryName: map['category_name'] as String?,
      categoryIcon: map['category_icon'] as String?,
      categoryColor: map['category_color'] as int?,
    );
  }

  TransactionItem copyWith({
    int? id,
    int? categoryId,
    String? type,
    double? amount,
    String? transactionDate,
    String? description,
    String? createdAt,
    String? categoryName,
    String? categoryIcon,
    int? categoryColor,
  }) {
    return TransactionItem(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      transactionDate: transactionDate ?? this.transactionDate,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      categoryName: categoryName ?? this.categoryName,
      categoryIcon: categoryIcon ?? this.categoryIcon,
      categoryColor: categoryColor ?? this.categoryColor,
    );
  }
}
