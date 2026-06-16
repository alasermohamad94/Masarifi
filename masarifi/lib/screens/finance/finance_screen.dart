import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/transaction.dart';
import '../../providers/app_provider.dart';
import '../../utils/formatters.dart';
import '../../utils/chart_colors.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/currency_picker.dart';
import '../../widgets/expense_pie_chart.dart';
import 'add_transaction_screen.dart';

enum _ChartPeriod { daily, weekly, monthly }

class FinanceScreen extends StatefulWidget {
  const FinanceScreen({super.key});

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen> {
  _ChartPeriod _chartPeriod = _ChartPeriod.weekly;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الدخل والمصروفات'),
        actions: const [
          Padding(
            padding: EdgeInsets.only(left: 8),
            child: CurrencyPickerButton(),
          ),
          SizedBox(width: 8),
        ],
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.neonBlue),
            );
          }

          return RefreshIndicator(
            color: AppColors.neonBlue,
            onRefresh: provider.init,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildBalanceSection(provider),
                const SizedBox(height: 20),
                _buildPieChartSection(provider),
                const SizedBox(height: 20),
                _buildChartSection(provider),
                const SizedBox(height: 20),
                _buildTopCategories(provider),
                const SizedBox(height: 20),
                SectionHeader(title: 'آخر الحركات'),
                ...provider.transactions.reversed.take(10).map(
                      (t) => _TransactionTile(
                        transaction: t,
                        provider: provider,
                      ),
                    ),
                if (provider.transactions.isEmpty)
                  const EmptyState(
                    icon: Icons.account_balance_wallet_outlined,
                    message: 'لا توجد حركات مالية بعد\nاضغط + لإضافة حركة',
                  ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddTransaction(context),
        icon: const Icon(Icons.add),
        label: const Text('إضافة حركة'),
      ),
    );
  }

  void _openAddTransaction(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
    );
  }

  Widget _buildBalanceSection(AppProvider provider) {
    return Column(
      children: [
        NeonCard(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.cardBlue, Color(0xFF0D2847)],
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'الرصيد الحالي',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.neonBlue.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      provider.selectedCurrency.nameAr,
                      style: const TextStyle(
                        color: AppColors.neonBlue,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                provider.formatMoney(provider.currentBalance),
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: provider.currentBalance >= 0
                      ? AppColors.incomeGreen
                      : AppColors.expenseRed,
                  shadows: [
                    Shadow(
                      color: (provider.currentBalance >= 0
                              ? AppColors.incomeGreen
                              : AppColors.expenseRed)
                          .withValues(alpha: 0.5),
                      blurRadius: 20,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: BalanceCard(
                title: 'إجمالي الدخل',
                amount: provider.formatMoney(provider.totalIncome),
                icon: Icons.trending_up,
                color: AppColors.incomeGreen,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: BalanceCard(
                title: 'إجمالي المصروفات',
                amount: provider.formatMoney(provider.totalExpenses),
                icon: Icons.trending_down,
                color: AppColors.expenseRed,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPieChartSection(AppProvider provider) {
    return NeonCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.neonBlue.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.pie_chart, color: AppColors.neonBlue, size: 20),
              ),
              const SizedBox(width: 10),
              const Text(
                'توزيع المصروفات',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ExpensePieChart(
            data: provider.getExpensesByCategory(),
            currency: provider.selectedCurrency,
          ),
        ],
      ),
    );
  }

  Widget _buildChartSection(AppProvider provider) {
    final data = switch (_chartPeriod) {
      _ChartPeriod.daily => provider.getDailyData(),
      _ChartPeriod.weekly => provider.getWeeklyData(),
      _ChartPeriod.monthly => provider.getMonthlyData(),
    };
    final entries = data.entries.toList();

    return NeonCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'المصروفات',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              _ChartToggle(
                period: _chartPeriod,
                onChanged: (p) => setState(() => _chartPeriod = p),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: entries.every((e) => e.value == 0)
                ? const Center(
                    child: Text(
                      'لا توجد بيانات للعرض',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  )
                : BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: entries.map((e) => e.value).reduce((a, b) => a > b ? a : b) * 1.2,
                      barTouchData: BarTouchData(
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            return BarTooltipItem(
                              provider.formatMoney(rod.toY),
                              const TextStyle(color: AppColors.textPrimary),
                            );
                          },
                        ),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (index < 0 || index >= entries.length) {
                                return const SizedBox.shrink();
                              }
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  entries[index].key,
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 10,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        leftTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: AppColors.divider.withValues(alpha: 0.5),
                          strokeWidth: 1,
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: List.generate(entries.length, (i) {
                        final barColor = ChartColors.forIndex(i);
                        return BarChartGroupData(
                          x: i,
                          barRods: [
                            BarChartRodData(
                              toY: entries[i].value,
                              gradient: ChartColors.gradientFor(barColor),
                              width: 22,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(8),
                              ),
                            ),
                          ],
                        );
                      }),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopCategories(AppProvider provider) {
    final top = provider.topExpenseCategories.take(5).toList();
    if (top.isEmpty) return const SizedBox.shrink();

    final maxVal = top.first.value;

    return NeonCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'أكبر المصروفات',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          ...top.asMap().entries.map((indexed) {
            final entry = indexed.value;
            final i = indexed.key;
            final ratio = maxVal > 0 ? entry.value / maxVal : 0.0;
            final catColor = ChartColors.forCategory(entry.key, i);
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: catColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: catColor.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Icon(
                          _categoryIcon(entry.key),
                          size: 16,
                          color: catColor,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          categoryLabel(entry.key),
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        provider.formatMoney(entry.value),
                        style: TextStyle(
                          color: catColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: ratio,
                      minHeight: 8,
                      backgroundColor: AppColors.navyBlue,
                      valueColor: AlwaysStoppedAnimation(catColor),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'food':
        return Icons.restaurant;
      case 'transport':
        return Icons.directions_car;
      case 'rent':
        return Icons.home;
      case 'utilities':
        return Icons.bolt;
      case 'entertainment':
        return Icons.movie;
      case 'health':
        return Icons.medical_services;
      case 'shopping':
        return Icons.shopping_bag;
      default:
        return Icons.more_horiz;
    }
  }
}

class _ChartToggle extends StatelessWidget {
  final _ChartPeriod period;
  final ValueChanged<_ChartPeriod> onChanged;

  const _ChartToggle({required this.period, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.navyBlue,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ToggleChip(
            label: 'يومي',
            selected: period == _ChartPeriod.daily,
            onTap: () => onChanged(_ChartPeriod.daily),
          ),
          _ToggleChip(
            label: 'أسبوعي',
            selected: period == _ChartPeriod.weekly,
            onTap: () => onChanged(_ChartPeriod.weekly),
          ),
          _ToggleChip(
            label: 'شهري',
            selected: period == _ChartPeriod.monthly,
            onTap: () => onChanged(_ChartPeriod.monthly),
          ),
        ],
      ),
    );
  }
}

class _ToggleChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ToggleChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.neonBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.darkBlue : AppColors.textSecondary,
            fontSize: 12,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final FinancialTransaction transaction;
  final AppProvider provider;

  const _TransactionTile({
    required this.transaction,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type == TransactionType.income;
    final arrowColor = isIncome ? AppColors.incomeGreen : AppColors.expenseRed;

    return NeonCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      accentColor: arrowColor,
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
