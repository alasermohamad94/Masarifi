import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/currency.dart';
import '../models/debt.dart';
import '../models/task.dart';
import '../models/transaction.dart';
import '../services/storage_service.dart';
import '../utils/formatters.dart';

class AppProvider extends ChangeNotifier {
  final StorageService _storage = StorageService();
  final _uuid = const Uuid();

  List<FinancialTransaction> transactions = [];
  List<Debt> debts = [];
  List<TaskItem> tasks = [];
  List<String> customExpenseCategories = [];
  List<String> customIncomeCategories = [];
  AppCurrency selectedCurrency = AppCurrency.sar;
  bool isLoading = true;

  Future<void> init() async {
    isLoading = true;
    notifyListeners();
    transactions = await _storage.loadTransactions();
    debts = await _storage.loadDebts();
    tasks = await _storage.loadTasks();
    customExpenseCategories = await _storage.loadCustomExpenseCategories();
    customIncomeCategories = await _storage.loadCustomIncomeCategories();
    final currencyCode = await _storage.loadCurrencyCode();
    if (currencyCode != null) {
      selectedCurrency = AppCurrency.fromCode(currencyCode);
    }
    isLoading = false;
    notifyListeners();
  }

  String formatMoney(double amount) =>
      formatCurrency(amount, selectedCurrency);

  Future<void> setCurrency(AppCurrency currency) async {
    selectedCurrency = currency;
    await _storage.saveCurrencyCode(currency.code);
    notifyListeners();
  }

  // --- Finance ---

  List<String> categoriesFor(TransactionType type) {
    final builtIn =
        type == TransactionType.income ? incomeCategories : expenseCategories;
    final custom = type == TransactionType.income
        ? customIncomeCategories
        : customExpenseCategories;
    return [...builtIn, ...custom];
  }

  bool isBuiltInCategory(String category) {
    return incomeCategories.contains(category) ||
        expenseCategories.contains(category);
  }

  Future<void> addCustomCategory(TransactionType type, String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;

    final list = type == TransactionType.income
        ? customIncomeCategories
        : customExpenseCategories;

    final exists = categoriesFor(type).any(
      (c) => categoryLabel(c).toLowerCase() == trimmed.toLowerCase() ||
          c.toLowerCase() == trimmed.toLowerCase(),
    );
    if (exists) return;

    list.add(trimmed);
    if (type == TransactionType.income) {
      await _storage.saveCustomIncomeCategories(customIncomeCategories);
    } else {
      await _storage.saveCustomExpenseCategories(customExpenseCategories);
    }
    notifyListeners();
  }

  double get totalIncome => transactions
      .where((t) => t.type == TransactionType.income)
      .fold(0.0, (sum, t) => sum + t.amount);

  double get totalExpenses => transactions
      .where((t) => t.type == TransactionType.expense)
      .fold(0.0, (sum, t) => sum + t.amount);

  double get currentBalance => totalIncome - totalExpenses;

  Map<String, double> getExpensesByCategory() {
    final map = <String, double>{};
    for (final t in transactions.where((t) => t.type == TransactionType.expense)) {
      map[t.category] = (map[t.category] ?? 0) + t.amount;
    }
    return map;
  }

  List<MapEntry<String, double>> get topExpenseCategories {
    final entries = getExpensesByCategory().entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries;
  }

  Map<String, double> getDailyData() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final map = <String, double>{};

    for (var i = 6; i >= 0; i--) {
      final day = today.subtract(Duration(days: i));
      final key = '${day.day}/${day.month}';
      map[key] = 0;
    }

    for (final t in transactions.where((t) => t.type == TransactionType.expense)) {
      final tDay = DateTime(t.date.year, t.date.month, t.date.day);
      final key = '${tDay.day}/${tDay.month}';
      if (map.containsKey(key)) {
        map[key] = (map[key] ?? 0) + t.amount;
      }
    }
    return map;
  }

  Map<String, double> getWeeklyData() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday % 7));
    final map = <String, double>{};
    const days = ['أحد', 'إثن', 'ثلا', 'أرب', 'خمي', 'جمع', 'سبت'];
    for (var i = 0; i < 7; i++) {
      map[days[i]] = 0;
    }
    for (final t in transactions.where((t) => t.type == TransactionType.expense)) {
      final diff = t.date.difference(startOfWeek).inDays;
      if (diff >= 0 && diff < 7) {
        map[days[diff]] = (map[days[diff]] ?? 0) + t.amount;
      }
    }
    return map;
  }

  Map<String, double> getMonthlyData() {
    final now = DateTime.now();
    final map = <String, double>{};
    for (var i = 5; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      final key = '${month.month}/${month.year}';
      map[key] = 0;
    }
    for (final t in transactions.where((t) => t.type == TransactionType.expense)) {
      final key = '${t.date.month}/${t.date.year}';
      if (map.containsKey(key)) {
        map[key] = (map[key] ?? 0) + t.amount;
      }
    }
    return map;
  }

  Future<void> addTransaction(FinancialTransaction transaction) async {
    transactions.add(transaction);
    await _storage.saveTransactions(transactions);
    notifyListeners();
  }

  Future<void> updateTransaction(FinancialTransaction transaction) async {
    final index = transactions.indexWhere((t) => t.id == transaction.id);
    if (index != -1) {
      transactions[index] = transaction;
      await _storage.saveTransactions(transactions);
      notifyListeners();
    }
  }

  Future<void> deleteTransaction(String id) async {
    transactions.removeWhere((t) => t.id == id);
    await _storage.saveTransactions(transactions);
    notifyListeners();
  }

  String generateId() => _uuid.v4();

  // --- Debts ---

  List<Debt> get debtsOwedByMe =>
      debts.where((d) => d.direction == DebtDirection.owedByMe).toList();

  List<Debt> get debtsOwedToMe =>
      debts.where((d) => d.direction == DebtDirection.owedToMe).toList();

  List<Debt> get upcomingDebtReminders {
    final now = DateTime.now();
    return debts
        .where((d) =>
            d.reminderEnabled &&
            d.status != DebtStatus.paid &&
            d.dueDate.difference(now).inDays <= 3 &&
            d.dueDate.difference(now).inDays >= 0)
        .toList();
  }

  Future<void> addDebt(Debt debt) async {
    debts.add(debt);
    await _storage.saveDebts(debts);
    notifyListeners();
  }

  Future<void> updateDebt(Debt debt) async {
    final index = debts.indexWhere((d) => d.id == debt.id);
    if (index != -1) {
      debts[index] = debt;
      await _storage.saveDebts(debts);
      notifyListeners();
    }
  }

  Future<void> deleteDebt(String id) async {
    debts.removeWhere((d) => d.id == id);
    await _storage.saveDebts(debts);
    notifyListeners();
  }

  // --- Tasks ---

  List<TaskItem> get todoTasks =>
      tasks.where((t) => !t.isAppointment && t.shouldShowActive).toList()
        ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

  List<TaskItem> get completedTasks =>
      tasks.where((t) => t.isEffectivelyCompleted).toList()
        ..sort((a, b) => b.dateTime.compareTo(a.dateTime));

  List<TaskItem> get appointments =>
      tasks.where((t) => t.isAppointment && t.shouldShowInAppointmentsList).toList()
        ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

  List<TaskItem> get todayTasks {
    final today = DateTime.now();
    return tasks
        .where((t) =>
            !t.isAppointment &&
            t.shouldShowActive &&
            t.occursOn(today))
        .toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
  }

  List<TaskItem> get todayAppointments {
    final today = DateTime.now();
    return tasks
        .where((t) =>
            t.isAppointment &&
            t.shouldShowActive &&
            t.occursOn(today))
        .toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
  }

  List<TaskItem> get todaySchedule {
    return [...todayAppointments, ...todayTasks]
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
  }

  List<TaskItem> get overdueTasksWithPenalty {
    final now = DateTime.now();
    return tasks
        .where((t) =>
            t.shouldShowActive &&
            t.penaltyAmount != null &&
            t.dateTime.isBefore(now))
        .toList();
  }

  List<TaskItem> get upcomingAlerts {
    final now = DateTime.now();
    return tasks.where((t) {
      if (!t.shouldShowActive || t.alertBefore == null) return false;
      final alertTime = _getAlertTime(t);
      return alertTime.isAfter(now) &&
          alertTime.difference(now).inHours <= 24;
    }).toList();
  }

  DateTime _getAlertTime(TaskItem task) {
    final occurrence = task.hasRecurrence
        ? task.todayOccurrence
        : task.dateTime;
    switch (task.alertBefore!) {
      case AlertBefore.minutes15:
        return occurrence.subtract(const Duration(minutes: 15));
      case AlertBefore.hour1:
        return occurrence.subtract(const Duration(hours: 1));
      case AlertBefore.day1:
        return occurrence.subtract(const Duration(days: 1));
    }
  }

  Future<void> addTask(TaskItem task) async {
    tasks.add(task);
    await _storage.saveTasks(tasks);
    notifyListeners();
  }

  Future<void> updateTask(TaskItem task) async {
    final index = tasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      tasks[index] = task;
      await _storage.saveTasks(tasks);
      notifyListeners();
    }
  }

  Future<void> toggleTaskComplete(String id) async {
    final index = tasks.indexWhere((t) => t.id == id);
    if (index == -1) return;

    final task = tasks[index];

    if (task.hasRecurrence) {
      if (task.isCompletedToday) {
        tasks[index] = task.copyWith(clearLastCompletedDate: true);
      } else {
        tasks[index] = task.copyWith(
          lastCompletedDate: TaskItem.dateKey(DateTime.now()),
          isCompleted: false,
        );
      }
    } else {
      tasks[index] = task.copyWith(isCompleted: !task.isCompleted);
    }

    await _storage.saveTasks(tasks);
    notifyListeners();
  }

  Future<void> deleteTask(String id) async {
    tasks.removeWhere((t) => t.id == id);
    await _storage.saveTasks(tasks);
    notifyListeners();
  }
}
