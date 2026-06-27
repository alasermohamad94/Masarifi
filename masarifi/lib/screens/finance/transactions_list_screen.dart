import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/transaction.dart';
import '../../providers/app_provider.dart';
import '../../services/export_service.dart';
import '../../utils/formatters.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/export_sheet.dart';
import 'add_transaction_screen.dart';

enum TransactionListFilter { all, expense, income }

class TransactionsListScreen extends StatefulWidget {
  final TransactionListFilter initialFilter;

  const TransactionsListScreen({
    super.key,
    this.initialFilter = TransactionListFilter.all,
  });

  @override
  State<TransactionsListScreen> createState() => _TransactionsListScreenState();
}

class _TransactionsListScreenState extends State<TransactionsListScreen> {
  late TransactionListFilter _filter;
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _filter = widget.initialFilter;
    _searchController.addListener(() {
      setState(() => _query = _searchController.text.trim());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<FinancialTransaction> _filtered(List<FinancialTransaction> all) {
    var list = List<FinancialTransaction>.from(all)
      ..sort((a, b) => b.date.compareTo(a.date));

    list = switch (_filter) {
      TransactionListFilter.all => list,
      TransactionListFilter.expense =>
        list.where((t) => t.type == TransactionType.expense).toList(),
      TransactionListFilter.income =>
        list.where((t) => t.type == TransactionType.income).toList(),
    };

    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      list = list.where((t) {
        return categoryLabel(t.category).contains(_query) ||
            categoryLabel(t.category).toLowerCase().contains(q) ||
            t.category.toLowerCase().contains(q) ||
            (t.notes?.toLowerCase().contains(q) ?? false) ||
            t.amount.toString().contains(_query) ||
            formatDate(t.date).contains(_query);
      }).toList();
    }

    return list;
  }

  ExportScope get _exportScope => switch (_filter) {
        TransactionListFilter.expense => ExportScope.expenses,
        TransactionListFilter.income => ExportScope.income,
        TransactionListFilter.all => ExportScope.finance,
      };

  String get _title => switch (_filter) {
        TransactionListFilter.expense => 'جميع المصروفات',
        TransactionListFilter.income => 'جميع الدخل',
        TransactionListFilter.all => 'جميع الحركات',
      };

  Map<String, List<FinancialTransaction>> _groupByMonth(
    List<FinancialTransaction> items,
  ) {
    final monthFormat = DateFormat('MMMM yyyy', 'ar');
    final map = <String, List<FinancialTransaction>>{};
    for (final t in items) {
      final key = monthFormat.format(t.date);
      map.putIfAbsent(key, () => []).add(t);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
        actions: [
          IconButton(
            tooltip: 'مشاركة',
            icon: const Icon(Icons.share_outlined),
            onPressed: () => showExportSheet(context, scope: _exportScope),
          ),
        ],
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, _) {
          final items = _filtered(provider.transactions);
          final expenseCount = provider.transactions
              .where((t) => t.type == TransactionType.expense)
              .length;
          final incomeCount = provider.transactions
              .where((t) => t.type == TransactionType.income)
              .length;
          final grouped = _groupByMonth(items);

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'بحث بالفئة أو المبلغ أو التاريخ...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _query.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: _searchController.clear,
                          )
                        : null,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Row(
                  children: [
                    _FilterChip(
                      label: 'الكل (${provider.transactions.length})',
                      selected: _filter == TransactionListFilter.all,
                      onTap: () =>
                          setState(() => _filter = TransactionListFilter.all),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'مصروفات ($expenseCount)',
                      selected: _filter == TransactionListFilter.expense,
                      color: AppColors.expenseRed,
                      onTap: () => setState(
                          () => _filter = TransactionListFilter.expense),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'دخل ($incomeCount)',
                      selected: _filter == TransactionListFilter.income,
                      color: AppColors.incomeGreen,
                      onTap: () =>
                          setState(() => _filter = TransactionListFilter.income),
                    ),
                  ],
                ),
              ),
              if (_filter == TransactionListFilter.expense)
                _SummaryBanner(
                  label: 'إجمالي المصروفات',
                  amount: provider.formatMoney(provider.totalExpenses),
                  count: expenseCount,
                  color: AppColors.expenseRed,
                  icon: Icons.receipt_long,
                ),
              if (_filter == TransactionListFilter.income)
                _SummaryBanner(
                  label: 'إجمالي الدخل',
                  amount: provider.formatMoney(provider.totalIncome),
                  count: incomeCount,
                  color: AppColors.incomeGreen,
                  icon: Icons.savings_outlined,
                ),
              if (_filter == TransactionListFilter.all)
                _SummaryBanner(
                  label: 'الرصيد الحالي',
                  amount: provider.formatMoney(provider.currentBalance),
                  count: provider.transactions.length,
                  color: provider.currentBalance >= 0
                      ? AppColors.incomeGreen
                      : AppColors.expenseRed,
                  icon: Icons.account_balance_wallet,
                ),
              Expanded(
                child: items.isEmpty
                    ? EmptyState(
                        icon: Icons.receipt_long,
                        message: _query.isNotEmpty
                            ? 'لا توجد نتائج للبحث'
                            : _filter == TransactionListFilter.expense
                                ? 'لا توجد مصروفات مسجّلة'
                                : 'لا توجد حركات',
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _listItemCount(grouped),
                        itemBuilder: (context, index) {
                          return _buildGroupedItem(
                            context,
                            grouped,
                            index,
                            provider,
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  int _listItemCount(Map<String, List<FinancialTransaction>> grouped) {
    var count = 0;
    for (final entry in grouped.entries) {
      count += 1 + entry.value.length;
    }
    return count;
  }

  Widget _buildGroupedItem(
    BuildContext context,
    Map<String, List<FinancialTransaction>> grouped,
    int index,
    AppProvider provider,
  ) {
    var current = 0;
    for (final entry in grouped.entries) {
      if (index == current) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8, top: 4),
          child: Text(
            entry.key,
            style: const TextStyle(
              color: AppColors.neonBlue,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        );
      }
      current++;
      for (final t in entry.value) {
        if (index == current) {
          return _TransactionTile(
            transaction: t,
            provider: provider,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AddTransactionScreen(existing: t),
              ),
            ),
          );
        }
        current++;
      }
    }
    return const SizedBox.shrink();
  }
}

class _SummaryBanner extends StatelessWidget {
  final String label;
  final String amount;
  final int count;
  final Color color;
  final IconData icon;

  const _SummaryBanner({
    required this.label,
    required this.amount,
    required this.count,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: NeonCard(
        accentColor: color,
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    amount,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '$count حركة',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color? color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final accent = color ?? AppColors.neonBlue;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? accent.withValues(alpha: 0.2)
                : AppColors.navyBlue,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? accent : AppColors.divider,
              width: selected ? 2 : 1,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: selected ? accent : AppColors.textSecondary,
                fontSize: 11,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final FinancialTransaction transaction;
  final AppProvider provider;
  final VoidCallback onTap;

  const _TransactionTile({
    required this.transaction,
    required this.provider,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type == TransactionType.income;
    final arrowColor = isIncome ? AppColors.incomeGreen : AppColors.expenseRed;

    return NeonCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      accentColor: arrowColor,
      onTap: onTap,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.iconBackground(arrowColor),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cardBorder(arrowColor)),
            ),
            child: Icon(
              isIncome ? Icons.arrow_downward : Icons.arrow_upward,
              color: arrowColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  categoryLabel(transaction.category),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  formatDate(transaction.date),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                if (transaction.notes != null &&
                    transaction.notes!.isNotEmpty)
                  Text(
                    transaction.notes!,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          Text(
            '${isIncome ? '+' : '-'}${provider.formatMoney(transaction.amount)}',
            style: TextStyle(
              color: arrowColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
