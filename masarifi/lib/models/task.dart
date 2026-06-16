enum TaskCategory { work, study, sports, club, homework, other }

enum TaskPriority { high, medium, low }

enum RecurrenceType { none, daily, specificDays }

enum AlertBefore { minutes15, hour1, day1 }

/// أيام الأسبوع (DateTime.weekday): 1=إثنين ... 7=أحد
const weekdayLabels = {
  1: 'إثن',
  2: 'ثلا',
  3: 'أرب',
  4: 'خمي',
  5: 'جمع',
  6: 'سبت',
  7: 'أحد',
};

const allWeekdays = [7, 1, 2, 3, 4, 5, 6];

class TaskItem {
  final String id;
  final String title;
  final TaskCategory category;
  final DateTime dateTime;
  final TaskPriority priority;
  final RecurrenceType recurrence;
  final List<int> repeatWeekdays;
  final String? lastCompletedDate;
  final bool isCompleted;
  final bool isAppointment;
  final AlertBefore? alertBefore;
  final double? budgetAmount;
  final String? budgetCategory;
  final double? penaltyAmount;
  final String? penaltyNotes;

  TaskItem({
    required this.id,
    required this.title,
    required this.category,
    required this.dateTime,
    this.priority = TaskPriority.medium,
    this.recurrence = RecurrenceType.none,
    this.repeatWeekdays = const [],
    this.lastCompletedDate,
    this.isCompleted = false,
    this.isAppointment = false,
    this.alertBefore,
    this.budgetAmount,
    this.budgetCategory,
    this.penaltyAmount,
    this.penaltyNotes,
  });

  bool get hasFinancialLink => budgetAmount != null || penaltyAmount != null;

  bool get hasRecurrence => recurrence != RecurrenceType.none;

  static String dateKey(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  bool occursOn(DateTime date) {
    final start = DateTime(dateTime.year, dateTime.month, dateTime.day);
    final check = DateTime(date.year, date.month, date.day);
    if (check.isBefore(start)) return false;

    switch (recurrence) {
      case RecurrenceType.none:
        return start.year == check.year &&
            start.month == check.month &&
            start.day == check.day;
      case RecurrenceType.daily:
        return true;
      case RecurrenceType.specificDays:
        return repeatWeekdays.contains(check.weekday);
    }
  }

  bool get isCompletedToday =>
      lastCompletedDate == dateKey(DateTime.now());

  bool get isEffectivelyCompleted {
    if (hasRecurrence) return isCompletedToday;
    return isCompleted;
  }

  bool get shouldShowActive {
    if (isEffectivelyCompleted) return false;
    if (recurrence == RecurrenceType.none) return !isCompleted;
    return occursOn(DateTime.now());
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'category': category.name,
        'dateTime': dateTime.toIso8601String(),
        'priority': priority.name,
        'recurrence': recurrence.name,
        'repeatWeekdays': repeatWeekdays,
        'lastCompletedDate': lastCompletedDate,
        'isCompleted': isCompleted,
        'isAppointment': isAppointment,
        'alertBefore': alertBefore?.name,
        'budgetAmount': budgetAmount,
        'budgetCategory': budgetCategory,
        'penaltyAmount': penaltyAmount,
        'penaltyNotes': penaltyNotes,
      };

  factory TaskItem.fromJson(Map<String, dynamic> json) {
    final dateTime = DateTime.parse(json['dateTime'] as String);
    final recurrenceRaw = json['recurrence'] as String;
    RecurrenceType recurrence;
    List<int> repeatWeekdays;

    if (recurrenceRaw == 'weekly') {
      recurrence = RecurrenceType.specificDays;
      repeatWeekdays = [dateTime.weekday];
    } else {
      recurrence = RecurrenceType.values.byName(recurrenceRaw);
      repeatWeekdays = (json['repeatWeekdays'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          [];
    }

    if (recurrence == RecurrenceType.daily && repeatWeekdays.isEmpty) {
      repeatWeekdays = List.from(allWeekdays);
    }

    return TaskItem(
      id: json['id'] as String,
      title: json['title'] as String,
      category: TaskCategory.values.byName(json['category'] as String),
      dateTime: dateTime,
      priority: TaskPriority.values.byName(json['priority'] as String),
      recurrence: recurrence,
      repeatWeekdays: repeatWeekdays,
      lastCompletedDate: json['lastCompletedDate'] as String?,
      isCompleted: json['isCompleted'] as bool? ?? false,
      isAppointment: json['isAppointment'] as bool? ?? false,
      alertBefore: json['alertBefore'] != null
          ? AlertBefore.values.byName(json['alertBefore'] as String)
          : null,
      budgetAmount: (json['budgetAmount'] as num?)?.toDouble(),
      budgetCategory: json['budgetCategory'] as String?,
      penaltyAmount: (json['penaltyAmount'] as num?)?.toDouble(),
      penaltyNotes: json['penaltyNotes'] as String?,
    );
  }

  TaskItem copyWith({
    String? id,
    String? title,
    TaskCategory? category,
    DateTime? dateTime,
    TaskPriority? priority,
    RecurrenceType? recurrence,
    List<int>? repeatWeekdays,
    String? lastCompletedDate,
    bool? isCompleted,
    bool? isAppointment,
    AlertBefore? alertBefore,
    double? budgetAmount,
    String? budgetCategory,
    double? penaltyAmount,
    String? penaltyNotes,
    bool clearLastCompletedDate = false,
  }) {
    return TaskItem(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      dateTime: dateTime ?? this.dateTime,
      priority: priority ?? this.priority,
      recurrence: recurrence ?? this.recurrence,
      repeatWeekdays: repeatWeekdays ?? this.repeatWeekdays,
      lastCompletedDate:
          clearLastCompletedDate ? null : (lastCompletedDate ?? this.lastCompletedDate),
      isCompleted: isCompleted ?? this.isCompleted,
      isAppointment: isAppointment ?? this.isAppointment,
      alertBefore: alertBefore ?? this.alertBefore,
      budgetAmount: budgetAmount ?? this.budgetAmount,
      budgetCategory: budgetCategory ?? this.budgetCategory,
      penaltyAmount: penaltyAmount ?? this.penaltyAmount,
      penaltyNotes: penaltyNotes ?? this.penaltyNotes,
    );
  }
}

String taskCategoryLabel(TaskCategory category) {
  switch (category) {
    case TaskCategory.work:
      return 'عمل';
    case TaskCategory.study:
      return 'دراسة';
    case TaskCategory.sports:
      return 'رياضة';
    case TaskCategory.club:
      return 'نادي';
    case TaskCategory.homework:
      return 'واجب منزلي';
    case TaskCategory.other:
      return 'أخرى';
  }
}

String priorityLabel(TaskPriority priority) {
  switch (priority) {
    case TaskPriority.high:
      return 'عالية';
    case TaskPriority.medium:
      return 'متوسطة';
    case TaskPriority.low:
      return 'منخفضة';
  }
}

String recurrenceLabel(RecurrenceType recurrence, [List<int> days = const []]) {
  switch (recurrence) {
    case RecurrenceType.none:
      return 'بدون تكرار';
    case RecurrenceType.daily:
      return 'كل يوم';
    case RecurrenceType.specificDays:
      if (days.isEmpty) return 'أيام محددة';
      if (days.length == 7) return 'كل يوم';
      return days.map((d) => weekdayLabels[d] ?? '').join('، ');
  }
}

String alertBeforeLabel(AlertBefore alert) {
  switch (alert) {
    case AlertBefore.minutes15:
      return '15 دقيقة';
    case AlertBefore.hour1:
      return 'ساعة';
    case AlertBefore.day1:
      return 'يوم';
  }
}
