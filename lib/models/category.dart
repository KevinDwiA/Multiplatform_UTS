class Category {
  final int? id;
  final String name;
  final String type; // 'income' or 'expense'
  final String icon;
  final int color;

  Category({
    this.id,
    required this.name,
    required this.type,
    this.icon = 'category',
    this.color = 0xFF4CAF50,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'icon': icon,
      'color': color,
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] as int?,
      name: map['name'] as String,
      type: map['type'] as String,
      icon: map['icon'] as String? ?? 'category',
      color: map['color'] as int? ?? 0xFF4CAF50,
    );
  }

  Category copyWith({
    int? id,
    String? name,
    String? type,
    String? icon,
    int? color,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      icon: icon ?? this.icon,
      color: color ?? this.color,
    );
  }
}
