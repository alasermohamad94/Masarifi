enum DebtDirection { owedByMe, owedToMe }

enum DebtStatus { pending, partial, paid, deferred }

class Debt {
  final String id;
  final DebtDirection direction;
  final String personName;
  final double totalAmount;
  final double paidAmount;
  final DateTime dueDate;
  final DebtStatus status;
  final String? notes;
  final bool reminderEnabled;

  Debt({
    required this.id,
    required this.direction,
    required this.personName,
    required this.totalAmount,
    this.paidAmount = 0,
    required this.dueDate,
    this.status = DebtStatus.pending,
    this.notes,
    this.reminderEnabled = true,
  });

  double get remainingAmount => totalAmount - paidAmount;

  Map<String, dynamic> toJson() => {
        'id': id,
        'direction': direction.name,
        'personName': personName,
        'totalAmount': totalAmount,
        'paidAmount': paidAmount,
        'dueDate': dueDate.toIso8601String(),
        'status': status.name,
        'notes': notes,
        'reminderEnabled': reminderEnabled,
      };

  factory Debt.fromJson(Map<String, dynamic> json) {
    return Debt(
      id: json['id'] as String,
      direction: DebtDirection.values.byName(json['direction'] as String),
      personName: json['personName'] as String,
      totalAmount: (json['totalAmount'] as num).toDouble(),
      paidAmount: (json['paidAmount'] as num?)?.toDouble() ?? 0,
      dueDate: DateTime.parse(json['dueDate'] as String),
      status: DebtStatus.values.byName(json['status'] as String),
      notes: json['notes'] as String?,
      reminderEnabled: json['reminderEnabled'] as bool? ?? true,
    );
  }

  Debt copyWith({
    String? id,
    DebtDirection? direction,
    String? personName,
    double? totalAmount,
    double? paidAmount,
    DateTime? dueDate,
    DebtStatus? status,
    String? notes,
    bool? reminderEnabled,
  }) {
    return Debt(
      id: id ?? this.id,
      direction: direction ?? this.direction,
      personName: personName ?? this.personName,
      totalAmount: totalAmount ?? this.totalAmount,
      paidAmount: paidAmount ?? this.paidAmount,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
    );
  }
}

String debtStatusLabel(DebtStatus status) {
  switch (status) {
    case DebtStatus.pending:
      return 'معلق';
    case DebtStatus.partial:
      return 'مدفوع جزئياً';
    case DebtStatus.paid:
      return 'مدفوع كلياً';
    case DebtStatus.deferred:
      return 'مؤجل';
  }
}
