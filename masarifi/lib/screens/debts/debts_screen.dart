import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/debt.dart';
import '../../providers/app_provider.dart';
import '../../utils/chart_colors.dart';
import '../../utils/formatters.dart';
import '../../widgets/common_widgets.dart';
import 'add_debt_screen.dart';

class DebtsScreen extends StatelessWidget {
  const DebtsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Builder(
        builder: (context) {
          final tabController = DefaultTabController.of(context);
          return Scaffold(
            appBar: AppBar(
              title: const Text('الديون'),
              bottom: TabBar(
                controller: tabController,
                indicatorColor: AppColors.neonBlue,
                labelColor: AppColors.neonBlue,
                unselectedLabelColor: AppColors.textSecondary,
                tabs: const [
                  Tab(
                    icon: Icon(Icons.arrow_upward, size: 18, color: DebtColors.owedByMe),
                    text: 'ديون عليّ',
                  ),
                  Tab(
                    icon: Icon(Icons.arrow_downward, size: 18, color: DebtColors.owedToMe),
                    text: 'ديون لي',
                  ),
                ],
              ),
            ),
            body: Consumer<AppProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.neonBlue),
                  );
                }

                final reminders = provider.upcomingDebtReminders;
                final owedByMeTotal = provider.debtsOwedByMe
                    .where((d) => d.status != DebtStatus.paid)
                    .fold(0.0, (s, d) => s + d.remainingAmount);
                final owedToMeTotal = provider.debtsOwedToMe
                    .where((d) => d.status != DebtStatus.paid)
                    .fold(0.0, (s, d) => s + d.remainingAmount);

                return Column(
                  children: [
                    if (reminders.isNotEmpty) _RemindersBanner(debts: reminders),
                    Expanded(
                      child: TabBarView(
                        controller: tabController,
                        children: [
                          _DebtList(
                            debts: provider.debtsOwedByMe,
                            emptyMessage: 'لا توجد ديون عليك',
                            provider: provider,
                            isOwedByMe: true,
                            totalRemaining: owedByMeTotal,
                          ),
                          _DebtList(
                            debts: provider.debtsOwedToMe,
                            emptyMessage: 'لا أحد مدين لك',
                            provider: provider,
                            isOwedByMe: false,
                            totalRemaining: owedToMeTotal,
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
            floatingActionButton: FloatingActionButton.extended(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddDebtScreen()),
              ),
              icon: const Icon(Icons.add),
              label: const Text('إضافة دين'),
            ),
          );
        },
      ),
    );
  }
}

class _RemindersBanner extends StatelessWidget {
  final List<Debt> debts;

  const _RemindersBanner({required this.debts});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warningOrange.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warningOrange.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.notifications_active, color: AppColors.warningOrange),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'تذكير بموعد السداد',
                  style: TextStyle(
                    color: AppColors.warningOrange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${debts.length} دين يستحق خلال 3 أيام',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DebtList extends StatelessWidget {
  final List<Debt> debts;
  final String emptyMessage;
  final AppProvider provider;
  final bool isOwedByMe;
  final double totalRemaining;

  const _DebtList({
    required this.debts,
    required this.emptyMessage,
    required this.provider,
    required this.isOwedByMe,
    required this.totalRemaining,
  });

  @override
  Widget build(BuildContext context) {
    if (debts.isEmpty) {
      return Column(
        children: [
          _SummaryBanner(
            isOwedByMe: isOwedByMe,
            total: totalRemaining,
            count: 0,
            provider: provider,
          ),
          Expanded(
            child: EmptyState(
              icon: Icons.money_off,
              message: emptyMessage,
            ),
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SummaryBanner(
          isOwedByMe: isOwedByMe,
          total: totalRemaining,
          count: debts.where((d) => d.status != DebtStatus.paid).length,
          provider: provider,
        ),
        ...debts.map((debt) => _DebtCard(
              debt: debt,
              provider: provider,
            )),
      ],
    );
  }
}

class _SummaryBanner extends StatelessWidget {
  final bool isOwedByMe;
  final double total;
  final int count;
  final AppProvider provider;

  const _SummaryBanner({
    required this.isOwedByMe,
    required this.total,
    required this.count,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    final accent = DebtColors.accentColor(isOwedByMe);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: DebtColors.cardBackground(isOwedByMe),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DebtColors.borderColor(isOwedByMe)),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.iconBackground(accent),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.cardBorder(accent)),
            ),
            child: Icon(
              isOwedByMe ? Icons.trending_down : Icons.trending_up,
              color: accent,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isOwedByMe ? 'إجمالي ما عليك' : 'إجمالي ما لك',
                  style: TextStyle(
                    color: accent.withValues(alpha: 0.9),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  provider.formatMoney(total),
                  style: TextStyle(
                    color: accent,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.softFill(accent),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.cardBorder(accent)),
            ),
            child: Text(
              '$count ${count == 1 ? 'دين' : 'ديون'}',
              style: TextStyle(
                color: accent,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DebtCard extends StatelessWidget {
  final Debt debt;
  final AppProvider provider;

  const _DebtCard({required this.debt, required this.provider});

  Color _statusColor(DebtStatus status) {
    switch (status) {
      case DebtStatus.paid:
        return AppColors.incomeGreen;
      case DebtStatus.partial:
        return AppColors.warningOrange;
      case DebtStatus.deferred:
        return AppColors.textSecondary;
      case DebtStatus.pending:
        return AppColors.expenseRed;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOwedByMe = debt.direction == DebtDirection.owedByMe;
    final accent = DebtColors.accentColor(isOwedByMe);
    final daysLeft = debt.dueDate.difference(DateTime.now()).inDays;
    final isPaid = debt.status == DebtStatus.paid;

    return NeonCard(
      padding: const EdgeInsets.all(16),
      backgroundColor: DebtColors.cardBackground(isOwedByMe),
      accentColor: accent,
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => AddDebtScreen(existing: debt)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.iconBackground(accent),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.cardBorder(accent)),
                ),
                child: Center(
                  child: Text(
                    debt.personName.isNotEmpty ? debt.personName[0] : '?',
                    style: TextStyle(
                      color: accent,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      debt.personName,
                      style: TextStyle(
                        color: isPaid ? AppColors.textSecondary : AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        decoration: isPaid ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    Row(
                      children: [
                        Icon(
                          isOwedByMe ? Icons.arrow_upward : Icons.arrow_downward,
                          size: 12,
                          color: accent,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isOwedByMe ? 'دائن' : 'مدين',
                          style: TextStyle(
                            color: accent.withValues(alpha: 0.85),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor(debt.status).withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _statusColor(debt.status).withValues(alpha: 0.35),
                  ),
                ),
                child: Text(
                  debtStatusLabel(debt.status),
                  style: TextStyle(
                    color: _statusColor(debt.status),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.darkBlue.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _InfoItem(
                  label: 'المبلغ',
                  value: provider.formatMoney(debt.totalAmount),
                ),
                _InfoItem(
                  label: 'المتبقي',
                  value: provider.formatMoney(debt.remainingAmount),
                  color: accent,
                ),
                _InfoItem(
                  label: 'الاستحقاق',
                  value: formatDate(debt.dueDate),
                ),
              ],
            ),
          ),
          if (!isPaid && debt.totalAmount > 0) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: debt.paidAmount / debt.totalAmount,
                minHeight: 5,
                backgroundColor: AppColors.navyBlue,
                valueColor: AlwaysStoppedAnimation(accent),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'تم سداد ${((debt.paidAmount / debt.totalAmount) * 100).toStringAsFixed(0)}%',
              style: TextStyle(color: accent.withValues(alpha: 0.8), fontSize: 10),
            ),
          ],
          if (!isPaid && daysLeft <= 3 && daysLeft >= 0)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: (daysLeft == 0 ? AppColors.expenseRed : AppColors.warningOrange)
                      .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 14,
                      color: daysLeft == 0
                          ? AppColors.expenseRed
                          : AppColors.warningOrange,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      daysLeft == 0
                          ? 'يستحق اليوم!'
                          : 'باقي $daysLeft ${daysLeft == 1 ? 'يوم' : 'أيام'}',
                      style: TextStyle(
                        color: daysLeft == 0
                            ? AppColors.expenseRed
                            : AppColors.warningOrange,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _InfoItem({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: color ?? AppColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
