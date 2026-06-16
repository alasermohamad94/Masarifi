import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../models/task.dart';
import '../providers/app_provider.dart';
import '../screens/debts/debts_screen.dart';
import '../screens/finance/finance_screen.dart';
import '../screens/tasks/tasks_screen.dart';
import '../utils/formatters.dart';
import '../widgets/common_widgets.dart';
import '../widgets/currency_picker.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final _screens = const [
    _DashboardTab(),
    FinanceScreen(),
    DebtsScreen(),
    TasksScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: AppColors.neonBlue.withValues(alpha: 0.2)),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'الرئيسية',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_wallet_outlined),
              activeIcon: Icon(Icons.account_balance_wallet),
              label: 'المالية',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.credit_card_outlined),
              activeIcon: Icon(Icons.credit_card),
              label: 'الديون',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.task_outlined),
              activeIcon: Icon(Icons.task),
              label: 'المهام',
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardTab extends StatelessWidget {
  const _DashboardTab();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.neonBlue.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.account_balance, color: AppColors.neonBlue, size: 20),
            ),
            const SizedBox(width: 8),
            const Text('مصاريفي'),
          ],
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(left: 12),
            child: CurrencyPickerButton(),
          ),
        ],
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.neonBlue),
            );
          }

          final reminders = provider.upcomingDebtReminders;
          final overduePenalties = provider.overdueTasksWithPenalty;
          final todaySchedule = provider.todaySchedule;
          final todayAppointments = provider.todayAppointments;
          final todayTasks = provider.todayTasks;
          final now = DateTime.now();
          final todayLabel = formatDate(now);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              NeonCard(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1A3050), Color(0xFF0D2847)],
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'مرحباً بك 👋',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      provider.formatMoney(provider.currentBalance),
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: provider.currentBalance >= 0
                            ? AppColors.neonBlue
                            : AppColors.expenseRed,
                      ),
                    ),
                    const Text(
                      'الرصيد الحالي',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: BalanceCard(
                      title: 'الدخل',
                      amount: provider.formatMoney(provider.totalIncome),
                      icon: Icons.arrow_downward,
                      color: AppColors.incomeGreen,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: BalanceCard(
                      title: 'المصروفات',
                      amount: provider.formatMoney(provider.totalExpenses),
                      icon: Icons.arrow_upward,
                      color: AppColors.expenseRed,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _TodayScheduleSection(
                dateLabel: todayLabel,
                schedule: todaySchedule,
                appointments: todayAppointments,
                tasks: todayTasks,
              ),
              if (reminders.isNotEmpty || overduePenalties.isNotEmpty) ...[
                const SizedBox(height: 20),
                SectionHeader(title: 'تنبيهات'),
                if (reminders.isNotEmpty)
                  _AlertTile(
                    icon: Icons.notifications_active,
                    color: AppColors.warningOrange,
                    title: '${reminders.length} دين يستحق قريباً',
                    subtitle: 'تحقق من قسم الديون',
                  ),
                if (overduePenalties.isNotEmpty)
                  _AlertTile(
                    icon: Icons.warning_amber,
                    color: AppColors.expenseRed,
                    title: '${overduePenalties.length} مهمة بغرامة محتملة',
                    subtitle: overduePenalties.first.title,
                  ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _TodayScheduleSection extends StatelessWidget {
  final String dateLabel;
  final List<TaskItem> schedule;
  final List<TaskItem> appointments;
  final List<TaskItem> tasks;

  const _TodayScheduleSection({
    required this.dateLabel,
    required this.schedule,
    required this.appointments,
    required this.tasks,
  });

  @override
  Widget build(BuildContext context) {
    return NeonCard(
      padding: const EdgeInsets.all(16),
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
                child: const Icon(Icons.calendar_today,
                    color: AppColors.neonBlue, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'جدول اليوم',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      dateLabel,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              _CountBadge(
                count: appointments.length,
                label: 'مواعيد',
                color: AppColors.accentPurple,
              ),
              const SizedBox(width: 6),
              _CountBadge(
                count: tasks.length,
                label: 'مهام',
                color: AppColors.neonBlueDim,
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (schedule.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24),
              decoration: BoxDecoration(
                color: AppColors.navyBlue.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                children: [
                  Icon(Icons.event_available,
                      color: AppColors.textSecondary, size: 36),
                  SizedBox(height: 8),
                  Text(
                    'لا توجد مهام أو مواعيد اليوم',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            )
          else
            ...schedule.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isLast = index == schedule.length - 1;
              return _ScheduleItemTile(
                task: item,
                isLast: isLast,
                onToggle: () =>
                    context.read<AppProvider>().toggleTaskComplete(item.id),
              );
            }),
        ],
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  final int count;
  final String label;
  final Color color;

  const _CountBadge({
    required this.count,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        '$count $label',
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ScheduleItemTile extends StatelessWidget {
  final TaskItem task;
  final bool isLast;
  final VoidCallback onToggle;

  const _ScheduleItemTile({
    required this.task,
    required this.isLast,
    required this.onToggle,
  });

  Color get _accentColor =>
      task.isAppointment ? AppColors.accentPurple : AppColors.neonBlueDim;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isPast = task.dateTime.isBefore(now);
    final timeStr = formatTime(task.dateTime);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 56,
            child: Column(
              children: [
                Text(
                  timeStr,
                  style: TextStyle(
                    color: isPast ? AppColors.textSecondary : _accentColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      const SizedBox(height: 4),
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: _accentColor.withValues(alpha: 0.25),
                          shape: BoxShape.circle,
                          border: Border.all(color: _accentColor, width: 2),
                        ),
                      ),
                      if (!isLast)
                        Expanded(
                          child: Container(
                            width: 2,
                            color: AppColors.divider.withValues(alpha: 0.6),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              margin: EdgeInsets.only(bottom: isLast ? 0 : 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _accentColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _accentColor.withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                children: [
                  if (!task.isAppointment)
                    GestureDetector(
                      onTap: onToggle,
                      child: Container(
                        width: 22,
                        height: 22,
                        margin: const EdgeInsets.only(left: 4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: _accentColor, width: 1.5),
                        ),
                      ),
                    ),
                  if (!task.isAppointment) const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              task.isAppointment ? Icons.event : Icons.task_alt,
                              size: 14,
                              color: _accentColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              task.isAppointment ? 'موعد' : 'مهمة',
                              style: TextStyle(
                                color: _accentColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (task.hasRecurrence) ...[
                              const SizedBox(width: 6),
                              Icon(
                                Icons.repeat,
                                size: 12,
                                color: _accentColor.withValues(alpha: 0.7),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          task.title,
                          style: TextStyle(
                            color: isPast
                                ? AppColors.textSecondary
                                : AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        if (!task.isAppointment) ...[
                          const SizedBox(height: 2),
                          Text(
                            taskCategoryLabel(task.category),
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                        if (task.isAppointment && task.alertBefore != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              'تنبيه قبل ${alertBeforeLabel(task.alertBefore!)}',
                              style: TextStyle(
                                color: AppColors.warningOrange.withValues(alpha: 0.9),
                                fontSize: 10,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  _PriorityDot(priority: task.priority),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PriorityDot extends StatelessWidget {
  final TaskPriority priority;

  const _PriorityDot({required this.priority});

  Color get _color {
    switch (priority) {
      case TaskPriority.high:
        return AppColors.expenseRed;
      case TaskPriority.medium:
        return AppColors.warningOrange;
      case TaskPriority.low:
        return AppColors.incomeGreen;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: _color,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _AlertTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  const _AlertTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return NeonCard(
      padding: const EdgeInsets.all(12),
      accentColor: color,
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(color: color, fontWeight: FontWeight.w600),
                ),
                Text(
                  subtitle,
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
