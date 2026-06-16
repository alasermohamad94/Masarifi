enum TransactionType { income, expense }

enum ExpenseCategory {
  food,
  transport,
  rent,
  utilities,
  entertainment,
  health,
  shopping,
  other,
}

enum IncomeCategory {
  salary,
  freelance,
  investment,
  gift,
  other,
}

class FinancialTransaction {
  final String id;
  final TransactionType type;
  final String category;
  final double amount;
  final DateTime date;
  final String? notes;
  final String? linkedTaskId;

  FinancialTransaction({
    required this.id,
    required this.type,
    required this.category,
    required this.amount,
    required this.date,
    this.notes,
    this.linkedTaskId,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'category': category,
        'amount': amount,
        'date': date.toIso8601String(),
        'notes': notes,
        'linkedTaskId': linkedTaskId,
      };

  factory FinancialTransaction.fromJson(Map<String, dynamic> json) {
    return FinancialTransaction(
      id: json['id'] as String,
      type: TransactionType.values.byName(json['type'] as String),
      category: json['category'] as String,
      amount: (json['amount'] as num).toDouble(),
      date: DateTime.parse(json['date'] as String),
      notes: json['notes'] as String?,
      linkedTaskId: json['linkedTaskId'] as String?,
    );
  }

  FinancialTransaction copyWith({
    String? id,
    TransactionType? type,
    String? category,
    double? amount,
    DateTime? date,
    String? notes,
    String? linkedTaskId,
  }) {
    return FinancialTransaction(
      id: id ?? this.id,
      type: type ?? this.type,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      linkedTaskId: linkedTaskId ?? this.linkedTaskId,
    );
  }
}

String categoryLabel(String category) {
  const labels = {
    'food': 'أكل',
    'transport': 'مواصلات',
    'rent': 'إيجار',
    'utilities': 'فواتير',
    'entertainment': 'ترفيه',
    'health': 'صحة',
    'shopping': 'تسوق',
    'other': 'أخرى',
    'salary': 'راتب',
    'freelance': 'عمل حر',
    'investment': 'استثمار',
    'gift': 'هدية',
  };
  return labels[category] ?? category;
}

List<String> get expenseCategories =>
    ExpenseCategory.values.map((e) => e.name).toList();

List<String> get incomeCategories =>
    IncomeCategory.values.map((e) => e.name).toList();

bool isBuiltInCategoryKey(String category) =>
    expenseCategories.contains(category) ||
    incomeCategories.contains(category);
