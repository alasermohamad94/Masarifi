import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/debt.dart';
import '../models/task.dart';
import '../models/transaction.dart';

class StorageService {
  static const _transactionsKey = 'transactions';
  static const _debtsKey = 'debts';
  static const _tasksKey = 'tasks';
  static const _currencyKey = 'selected_currency';
  static const _customExpenseCategoriesKey = 'custom_expense_categories';
  static const _customIncomeCategoriesKey = 'custom_income_categories';

  Future<List<String>> loadCustomExpenseCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_customExpenseCategoriesKey);
    if (json == null) return [];
    return (jsonDecode(json) as List).cast<String>();
  }

  Future<List<String>> loadCustomIncomeCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_customIncomeCategoriesKey);
    if (json == null) return [];
    return (jsonDecode(json) as List).cast<String>();
  }

  Future<void> saveCustomExpenseCategories(List<String> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_customExpenseCategoriesKey, jsonEncode(items));
  }

  Future<void> saveCustomIncomeCategories(List<String> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_customIncomeCategoriesKey, jsonEncode(items));
  }

  Future<String?> loadCurrencyCode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_currencyKey);
  }

  Future<void> saveCurrencyCode(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currencyKey, code);
  }

  Future<List<FinancialTransaction>> loadTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_transactionsKey);
    if (json == null) return [];
    final list = jsonDecode(json) as List;
    return list
        .map((e) => FinancialTransaction.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveTransactions(List<FinancialTransaction> items) async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(items.map((e) => e.toJson()).toList());
    await prefs.setString(_transactionsKey, json);
  }

  Future<List<Debt>> loadDebts() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_debtsKey);
    if (json == null) return [];
    final list = jsonDecode(json) as List;
    return list
        .map((e) => Debt.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveDebts(List<Debt> items) async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(items.map((e) => e.toJson()).toList());
    await prefs.setString(_debtsKey, json);
  }

  Future<List<TaskItem>> loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_tasksKey);
    if (json == null) return [];
    final list = jsonDecode(json) as List;
    return list
        .map((e) => TaskItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveTasks(List<TaskItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(items.map((e) => e.toJson()).toList());
    await prefs.setString(_tasksKey, json);
  }
}
