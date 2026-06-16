import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/task.dart';
import '../../providers/app_provider.dart';
import '../../utils/formatters.dart';
import '../../widgets/common_widgets.dart';
import 'add_task_screen.dart';

class TasksScreen extends StatelessWidget {
  const TasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('المهام والمواعيد'),
          bottom: const TabBar(
            isScrollable: true,
            indicatorColor: AppColors.neonBlue,
            labelColor: AppColors.neonBlue,
            unselectedLabelColor: AppColors.textSecondary,
            tabs: [
              Tab(text: 'للقيام'),
              Tab(text: 'منجزة'),
              Tab(text: 'مواعيد'),
              Tab(text: 'ربط مالي'),
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

            return TabBarView(
              children: [
                _TodoTab(tasks: provider.todoTasks),
                _CompletedTab(tasks: provider.completedTasks),
                _AppointmentsTab(appointments: provider.appointments),
                _FinancialLinkTab(provider: provider),
              ],
            );
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddTaskScreen()),
          ),
          icon: const Icon(Icons.add),
          label: const Text('إضافة'),
        ),
      ),
    );
  }
}

class _TodoTab extends StatelessWidget {
  final List<TaskItem> tasks;

  const _TodoTab({required this.tasks});

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) {
      return const EmptyState(
        icon: Icons.checklist,
        message: 'لا توجد مهام\nاضغط + لإضافة مهمة',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tasks.length,
      itemBuilder: (context, index) => _TaskCard(
        task: tasks[index],
        onToggle: () => _toggleTask(context, tasks[index]),
      ),
    );
  }

  Future<void> _toggleTask(BuildContext context, TaskItem task) async {
    await context.read<AppProvider>().toggleTaskComplete(task.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم تحويل "${task.title}" إلى منجزة'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}

class _CompletedTab extends StatelessWidget {
  final List<TaskItem> tasks;

  const _CompletedTab({required this.tasks});

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) {
      return const EmptyState(
        icon: Icons.task_alt,
        message: 'لا توجد مهام منجزة بعد',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tasks.length,
      itemBuilder: (context, index) => _TaskCard(
        task: tasks[index],
        isCompletedTab: true,
        onToggle: () => _restoreTask(context, tasks[index]),
      ),
    );
  }

  Future<void> _restoreTask(BuildContext context, TaskItem task) async {
    await context.read<AppProvider>().toggleTaskComplete(task.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم إرجاع "${task.title}" إلى قائمة المهام'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}

class _AppointmentsTab extends StatelessWidget {
  final List<TaskItem> appointments;

  const _AppointmentsTab({required this.appointments});

  @override
  Widget build(BuildContext context) {
    if (appointments.isEmpty) {
      return const EmptyState(
        icon: Icons.event,
        message: 'لا توجد مواعيد\nاضغط + لإضافة موعد',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: appointments.length,
      itemBuilder: (context, index) => _TaskCard(
        task: appointments[index],
        showAlert: true,
        onToggle: () => _completeAppointment(context, appointments[index]),
      ),
    );
  }

  Future<void> _completeAppointment(BuildContext context, TaskItem task) async {
    await context.read<AppProvider>().toggleTaskComplete(task.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم إنجاز الموعد "${task.title}"'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}

class _FinancialLinkTab extends StatelessWidget {
  final AppProvider provider;

  const _FinancialLinkTab({required this.provider});

  @override
  Widget build(BuildContext context) {
    final linkedTasks = provider.tasks
        .where((t) => t.hasFinancialLink && t.shouldShowActive)
        .toList();
    final overduePenalties = provider.overdueTasksWithPenalty;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (overduePenalties.isNotEmpty) ...[
          NeonCard(
            gradient: LinearGradient(
              colors: [
                AppColors.expenseRed.withValues(alpha: 0.2),
                AppColors.cardBlue,
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.warning_amber, color: AppColors.expenseRed),
                    SizedBox(width: 8),
                    Text(
                      'تذكير مزدوج - غرامات محتملة',
                      style: TextStyle(
                        color: AppColors.expenseRed,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...overduePenalties.map((t) => Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              t.title,
                              style: const TextStyle(color: AppColors.textPrimary),
                            ),
                          ),
                          Text(
                            provider.formatMoney(t.penaltyAmount!),
                            style: const TextStyle(
                              color: AppColors.expenseRed,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    )),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        SectionHeader(title: 'مهام بميزانية'),
        if (linkedTasks.isEmpty)
          const EmptyState(
            icon: Icons.link_off,
            message: 'لا توجد مهام مرتبطة مالياً',
          )
        else
          ...linkedTasks.map((t) => _FinancialTaskCard(task: t, provider: provider)),
      ],
    );
  }
}

class _TaskCard extends StatelessWidget {
  final TaskItem task;
  final bool showAlert;
  final bool isCompletedTab;
  final VoidCallback onToggle;

  const _TaskCard({
    required this.task,
    this.showAlert = false,
    this.isCompletedTab = false,
    required this.onToggle,
  });

  Color _priorityColor(TaskPriority priority) {
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
    final isCompleted = isCompletedTab || task.isEffectivelyCompleted;

    return NeonCard(
      padding: const EdgeInsets.all(16),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => AddTaskScreen(existing: task)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onToggle,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isCompleted
                      ? AppColors.incomeGreen
                      : AppColors.neonBlue,
                  width: 2,
                ),
                color: isCompleted
                    ? AppColors.incomeGreen.withValues(alpha: 0.2)
                    : Colors.transparent,
              ),
              child: isCompleted
                  ? const Icon(Icons.check, size: 16, color: AppColors.incomeGreen)
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: TextStyle(
                    color: isCompleted
                        ? AppColors.textSecondary
                        : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      task.isAppointment ? Icons.event : Icons.category,
                      size: 12,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isCompletedTab
                          ? (task.isAppointment ? 'موعد منجز' : 'مهمة منجزة')
                          : (task.isAppointment
                              ? 'موعد'
                              : taskCategoryLabel(task.category)),
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      formatDateTime(task.dateTime),
                      style: TextStyle(
                        color: isCompleted
                            ? AppColors.textSecondary
                            : AppColors.neonBlueDim,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                if (showAlert && task.alertBefore != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.notifications,
                          size: 12,
                          color: AppColors.warningOrange,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'تنبيه قبل ${alertBeforeLabel(task.alertBefore!)}',
                          style: const TextStyle(
                            color: AppColors.warningOrange,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (task.hasRecurrence && !isCompletedTab)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.repeat,
                          size: 12,
                          color: AppColors.neonBlue,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          recurrenceLabel(task.recurrence, task.repeatWeekdays),
                          style: const TextStyle(
                            color: AppColors.neonBlue,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          if (!isCompletedTab)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _priorityColor(task.priority).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                priorityLabel(task.priority),
                style: TextStyle(
                  color: _priorityColor(task.priority),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else
            const Icon(Icons.check_circle, color: AppColors.incomeGreen, size: 20),
        ],
      ),
    );
  }
}

class _FinancialTaskCard extends StatelessWidget {
  final TaskItem task;
  final AppProvider provider;

  const _FinancialTaskCard({required this.task, required this.provider});

  @override
  Widget build(BuildContext context) {
    return NeonCard(
      padding: const EdgeInsets.all(16),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => AddTaskScreen(existing: task)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            task.title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          if (task.budgetAmount != null)
            Row(
              children: [
                const Icon(Icons.account_balance_wallet,
                    size: 16, color: AppColors.neonBlue),
                const SizedBox(width: 8),
                Text(
                  'ميزانية: ${provider.formatMoney(task.budgetAmount!)}',
                  style: const TextStyle(color: AppColors.neonBlue),
                ),
                if (task.budgetCategory != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    '(${categoryLabelFromTask(task.budgetCategory!)})',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          if (task.penaltyAmount != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  const Icon(Icons.gavel, size: 16, color: AppColors.expenseRed),
                  const SizedBox(width: 8),
                  Text(
                    'غرامة محتملة: ${provider.formatMoney(task.penaltyAmount!)}',
                    style: const TextStyle(color: AppColors.expenseRed),
                  ),
                ],
              ),
            ),
          if (task.penaltyNotes != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                task.penaltyNotes!,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

String categoryLabelFromTask(String category) {
  const labels = {
    'food': 'أكل',
    'transport': 'مواصلات',
    'rent': 'إيجار',
    'utilities': 'فواتير',
    'entertainment': 'ترفيه',
    'health': 'صحة',
    'shopping': 'تسوق',
    'other': 'أخرى',
  };
  return labels[category] ?? category;
}
