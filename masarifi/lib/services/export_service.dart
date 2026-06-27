import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/currency.dart';
import '../models/debt.dart';
import '../models/task.dart';
import '../models/transaction.dart';
import '../utils/formatters.dart';

enum ExportScope { full, finance, expenses, income, debts, tasks, appointments }

class ExportService {
  ExportService._();

  static const _channel = MethodChannel('masarifi/share');

  static String buildReport({
    required ExportScope scope,
    required List<FinancialTransaction> transactions,
    required List<Debt> debts,
    required List<TaskItem> tasks,
    required AppCurrency currency,
    required String Function(double) formatMoney,
  }) {
    return switch (scope) {
      ExportScope.full => _buildFullReport(
          transactions, debts, tasks, currency, formatMoney),
      ExportScope.finance => _buildFinanceReport(
          transactions, currency, formatMoney, includeIncome: true),
      ExportScope.expenses => _buildExpensesReport(
          transactions, currency, formatMoney),
      ExportScope.income => _buildIncomeReport(
          transactions, currency, formatMoney),
      ExportScope.debts =>
        _buildDebtsReport(debts, currency, formatMoney),
      ExportScope.tasks => _buildTasksReport(tasks),
      ExportScope.appointments => _buildAppointmentsReport(tasks),
    };
  }

  static String buildCsv({
    required ExportScope scope,
    required List<FinancialTransaction> transactions,
    required List<Debt> debts,
    required List<TaskItem> tasks,
    required AppCurrency currency,
  }) {
    return switch (scope) {
      ExportScope.full => _buildFullCsv(transactions, debts, tasks, currency),
      ExportScope.finance ||
      ExportScope.expenses ||
      ExportScope.income =>
        _buildTransactionsCsv(_filteredTransactions(transactions, scope),
            currency),
      ExportScope.debts => _buildDebtsCsv(debts, currency),
      ExportScope.tasks || ExportScope.appointments =>
        _buildTasksCsv(_filteredTasks(tasks, scope)),
    };
  }

  static String csvFileName(ExportScope scope) {
    return switch (scope) {
      ExportScope.full => 'masarifi_full_report.csv',
      ExportScope.finance => 'masarifi_finance.csv',
      ExportScope.expenses => 'masarifi_expenses.csv',
      ExportScope.income => 'masarifi_income.csv',
      ExportScope.debts => 'masarifi_debts.csv',
      ExportScope.tasks => 'masarifi_tasks.csv',
      ExportScope.appointments => 'masarifi_appointments.csv',
    };
  }

  static String scopeTitle(ExportScope scope) {
    return switch (scope) {
      ExportScope.full => 'تقرير شامل',
      ExportScope.finance => 'المالية',
      ExportScope.expenses => 'المصروفات',
      ExportScope.income => 'الدخل',
      ExportScope.debts => 'الديون',
      ExportScope.tasks => 'المهام',
      ExportScope.appointments => 'المواعيد',
    };
  }

  static Future<void> shareWhatsApp(String text) async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      await _channel.invokeMethod<void>('shareWhatsApp', {'text': text});
      return;
    }
    await shareText(text);
  }

  static Future<void> shareCsv({
    required String content,
    required String fileName,
  }) async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      await _channel.invokeMethod<void>('shareCsv', {
        'content': content,
        'fileName': fileName,
      });
      return;
    }
    await shareText(content);
  }

  static Future<void> shareText(String text) async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      await _channel.invokeMethod<void>('shareText', {'text': text});
      return;
    }
    await Clipboard.setData(ClipboardData(text: text));
  }

  static Future<void> shareReport({
    required ExportScope scope,
    required List<FinancialTransaction> transactions,
    required List<Debt> debts,
    required List<TaskItem> tasks,
    required AppCurrency currency,
    required String Function(double) formatMoney,
    required bool asCsv,
  }) async {
    if (asCsv) {
      await shareCsv(
        content: buildCsv(
          scope: scope,
          transactions: transactions,
          debts: debts,
          tasks: tasks,
          currency: currency,
        ),
        fileName: csvFileName(scope),
      );
    } else {
      await shareText(buildReport(
        scope: scope,
        transactions: transactions,
        debts: debts,
        tasks: tasks,
        currency: currency,
        formatMoney: formatMoney,
      ));
    }
  }

  static List<FinancialTransaction> _filteredTransactions(
    List<FinancialTransaction> all,
    ExportScope scope,
  ) {
    return switch (scope) {
      ExportScope.expenses =>
        all.where((t) => t.type == TransactionType.expense).toList(),
      ExportScope.income =>
        all.where((t) => t.type == TransactionType.income).toList(),
      _ => all,
    };
  }

  static List<TaskItem> _filteredTasks(List<TaskItem> all, ExportScope scope) {
    return switch (scope) {
      ExportScope.appointments =>
        all.where((t) => t.isAppointment).toList(),
      ExportScope.tasks => all.where((t) => !t.isAppointment).toList(),
      _ => all,
    };
  }

  static String _buildFullReport(
    List<FinancialTransaction> transactions,
    List<Debt> debts,
    List<TaskItem> tasks,
    AppCurrency currency,
    String Function(double) formatMoney,
  ) {
    final buffer = StringBuffer()
      ..writeln('📊 تقرير مصاريفي الشامل')
      ..writeln('العملة: ${currency.nameAr}')
      ..writeln('═══════════════════════')
      ..writeln(_buildFinanceReport(transactions, currency, formatMoney))
      ..writeln('═══════════════════════')
      ..writeln(_buildDebtsReport(debts, currency, formatMoney))
      ..writeln('═══════════════════════')
      ..writeln(_buildTasksReport(tasks))
      ..writeln('═══════════════════════')
      ..writeln(_buildAppointmentsReport(tasks))
      ..writeln('─────────────────')
      ..writeln('تطبيق مصاريفي');
    return buffer.toString();
  }

  static String _buildFinanceReport(
    List<FinancialTransaction> transactions,
    AppCurrency currency,
    String Function(double) formatMoney, {
    bool includeIncome = true,
  }) {
    final income = transactions
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (s, t) => s + t.amount);
    final expenses = transactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (s, t) => s + t.amount);

    final buffer = StringBuffer()
      ..writeln('💰 الملخص المالي')
      ..writeln('الدخل: ${formatMoney(income)}')
      ..writeln('المصروفات: ${formatMoney(expenses)}')
      ..writeln('الرصيد: ${formatMoney(income - expenses)}');

    if (includeIncome) {
      buffer.writeln(_transactionSection(
        transactions.where((t) => t.type == TransactionType.income).toList(),
        '💵 الدخل',
        formatMoney,
      ));
    }

    buffer.writeln(_transactionSection(
      transactions.where((t) => t.type == TransactionType.expense).toList(),
      '💸 المصروفات',
      formatMoney,
    ));

    return buffer.toString();
  }

  static String _buildExpensesReport(
    List<FinancialTransaction> transactions,
    AppCurrency currency,
    String Function(double) formatMoney,
  ) {
    final expenses = transactions
        .where((t) => t.type == TransactionType.expense)
        .toList();
    final total = expenses.fold(0.0, (s, t) => s + t.amount);

    final buffer = StringBuffer()
      ..writeln('💸 تقرير المصروفات')
      ..writeln('العملة: ${currency.nameAr}')
      ..writeln('الإجمالي: ${formatMoney(total)}')
      ..writeln('عدد الحركات: ${expenses.length}')
      ..writeln(_transactionSection(expenses, 'التفاصيل', formatMoney));

    final byCategory = <String, double>{};
    for (final t in expenses) {
      byCategory[t.category] = (byCategory[t.category] ?? 0) + t.amount;
    }
    if (byCategory.isNotEmpty) {
      buffer.writeln('── حسب الفئة ──');
      final sorted = byCategory.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      for (final e in sorted) {
        buffer.writeln('• ${categoryLabel(e.key)}: ${formatMoney(e.value)}');
      }
    }

    return buffer.toString();
  }

  static String _buildIncomeReport(
    List<FinancialTransaction> transactions,
    AppCurrency currency,
    String Function(double) formatMoney,
  ) {
    final income = transactions
        .where((t) => t.type == TransactionType.income)
        .toList();
    final total = income.fold(0.0, (s, t) => s + t.amount);

    final buffer = StringBuffer()
      ..writeln('💵 تقرير الدخل')
      ..writeln('العملة: ${currency.nameAr}')
      ..writeln('الإجمالي: ${formatMoney(total)}')
      ..writeln('عدد الحركات: ${income.length}')
      ..writeln(_transactionSection(income, 'التفاصيل', formatMoney));
    return buffer.toString();
  }

  static String _buildDebtsReport(
    List<Debt> debts,
    AppCurrency currency,
    String Function(double) formatMoney,
  ) {
    final owedByMe = debts
        .where((d) =>
            d.direction == DebtDirection.owedByMe && d.status != DebtStatus.paid)
        .toList();
    final owedToMe = debts
        .where((d) =>
            d.direction == DebtDirection.owedToMe && d.status != DebtStatus.paid)
        .toList();

    final buffer = StringBuffer()
      ..writeln('💳 تقرير الديون')
      ..writeln('العملة: ${currency.nameAr}')
      ..writeln(
        'عليّ: ${formatMoney(owedByMe.fold(0.0, (s, d) => s + d.remainingAmount))}',
      )
      ..writeln(
        'لي: ${formatMoney(owedToMe.fold(0.0, (s, d) => s + d.remainingAmount))}',
      );

    if (debts.isEmpty) {
      buffer.writeln('لا توجد ديون مسجّلة');
    } else {
      buffer.writeln('── التفاصيل ──');
      for (final d in debts) {
        final dir = d.direction == DebtDirection.owedByMe ? 'عليّ' : 'لي';
        buffer.writeln(
          '• $dir | ${d.personName} | ${formatMoney(d.totalAmount)} | متبقي ${formatMoney(d.remainingAmount)} | ${debtStatusLabel(d.status)} | ${formatDate(d.dueDate)}',
        );
      }
    }
    return buffer.toString();
  }

  static String _buildTasksReport(List<TaskItem> tasks) {
    final list = tasks.where((t) => !t.isAppointment).toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

    final buffer = StringBuffer()
      ..writeln('✅ تقرير المهام')
      ..writeln('عدد المهام: ${list.length}');

    if (list.isEmpty) {
      buffer.writeln('لا توجد مهام');
    } else {
      for (final t in list) {
        buffer.writeln(_taskLine(t));
      }
    }
    return buffer.toString();
  }

  static String _buildAppointmentsReport(List<TaskItem> tasks) {
    final list = tasks.where((t) => t.isAppointment).toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

    final buffer = StringBuffer()
      ..writeln('📅 تقرير المواعيد')
      ..writeln('عدد المواعيد: ${list.length}');

    if (list.isEmpty) {
      buffer.writeln('لا توجد مواعيد');
    } else {
      for (final t in list) {
        buffer.writeln(_taskLine(t));
      }
    }
    return buffer.toString();
  }

  static String _transactionSection(
    List<FinancialTransaction> list,
    String title,
    String Function(double) formatMoney,
  ) {
    final sorted = List<FinancialTransaction>.from(list)
      ..sort((a, b) => b.date.compareTo(a.date));
    final buffer = StringBuffer()..writeln('── $title (${sorted.length}) ──');

    if (sorted.isEmpty) {
      buffer.writeln('لا توجد حركات');
    } else {
      for (final t in sorted) {
        buffer.writeln(
          '• ${formatDate(t.date)} | ${categoryLabel(t.category)} | ${formatMoney(t.amount)}${t.notes != null && t.notes!.isNotEmpty ? ' — ${t.notes}' : ''}',
        );
      }
    }
    return buffer.toString();
  }

  static String _taskLine(TaskItem t) {
    final kind = t.isAppointment ? 'موعد' : 'مهمة';
    final recurrence = t.hasRecurrence
        ? ' | ${recurrenceLabel(t.recurrence, t.repeatWeekdays)}'
        : '';
    final alert = t.alertBefore != null
        ? ' | تنبيه ${alertBeforeLabel(t.alertBefore!)}'
        : '';
    return '• $kind | ${t.title} | ${formatDateTime(t.dateTime)}$recurrence$alert';
  }

  static String _buildFullCsv(
    List<FinancialTransaction> transactions,
    List<Debt> debts,
    List<TaskItem> tasks,
    AppCurrency currency,
  ) {
    final buffer = StringBuffer('\uFEFF')
      ..writeln('القسم,النوع,التفاصيل,المبلغ,العملة,التاريخ,ملاحظات');

    for (final t in transactions) {
      final type = t.type == TransactionType.income ? 'دخل' : 'مصروف';
      buffer.writeln(
        'مالية,$type,${categoryLabel(t.category)},${t.amount},${currency.code},${formatDate(t.date)},${_csvCell(t.notes)}',
      );
    }
    for (final d in debts) {
      final dir = d.direction == DebtDirection.owedByMe ? 'عليّ' : 'لي';
      buffer.writeln(
        'ديون,$dir,${d.personName},${d.remainingAmount},${currency.code},${formatDate(d.dueDate)},${debtStatusLabel(d.status)}',
      );
    }
    for (final t in tasks.where((t) => !t.isAppointment)) {
      buffer.writeln(
        'مهام,${taskCategoryLabel(t.category)},${t.title},,,${formatDateTime(t.dateTime)},${priorityLabel(t.priority)}',
      );
    }
    for (final t in tasks.where((t) => t.isAppointment)) {
      buffer.writeln(
        'مواعيد,${recurrenceLabel(t.recurrence, t.repeatWeekdays)},${t.title},,,${formatDateTime(t.dateTime)},',
      );
    }
    return buffer.toString();
  }

  static String _buildTransactionsCsv(
    List<FinancialTransaction> transactions,
    AppCurrency currency,
  ) {
    final sorted = List<FinancialTransaction>.from(transactions)
      ..sort((a, b) => b.date.compareTo(a.date));
    final buffer = StringBuffer('\uFEFF')
      ..writeln('النوع,الفئة,المبلغ,العملة,التاريخ,ملاحظات');
    for (final t in sorted) {
      final type = t.type == TransactionType.income ? 'دخل' : 'مصروف';
      buffer.writeln(
        '$type,${categoryLabel(t.category)},${t.amount},${currency.code},${formatDate(t.date)},${_csvCell(t.notes)}',
      );
    }
    return buffer.toString();
  }

  static String _buildDebtsCsv(List<Debt> debts, AppCurrency currency) {
    final buffer = StringBuffer('\uFEFF')
      ..writeln('الاتجاه,الشخص,المبلغ,المدفوع,المتبقي,الحالة,الاستحقاق,ملاحظات');
    for (final d in debts) {
      final dir = d.direction == DebtDirection.owedByMe ? 'عليّ' : 'لي';
      buffer.writeln(
        '$dir,${d.personName},${d.totalAmount},${d.paidAmount},${d.remainingAmount},${debtStatusLabel(d.status)},${formatDate(d.dueDate)},${_csvCell(d.notes)}',
      );
    }
    return buffer.toString();
  }

  static String _buildTasksCsv(List<TaskItem> tasks) {
    final buffer = StringBuffer('\uFEFF')
      ..writeln('النوع,العنوان,التاريخ,الأولوية,التكرار,ملاحظات');
    for (final t in tasks) {
      buffer.writeln(
        '${t.isAppointment ? 'موعد' : 'مهمة'},${t.title},${formatDateTime(t.dateTime)},${priorityLabel(t.priority)},${recurrenceLabel(t.recurrence, t.repeatWeekdays)},',
      );
    }
    return buffer.toString();
  }

  static String _csvCell(String? value) =>
      (value ?? '').replaceAll(',', '،');
}
