import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/currency.dart';
import '../../models/task.dart';
import '../../models/transaction.dart';
import '../../providers/app_provider.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/recurrence_picker.dart';

class AddTaskScreen extends StatefulWidget {
  final TaskItem? existing;

  const AddTaskScreen({super.key, this.existing});

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _budgetController = TextEditingController();
  final _penaltyController = TextEditingController();
  final _penaltyNotesController = TextEditingController();

  late TaskCategory _category;
  late DateTime _dateTime;
  late TaskPriority _priority;
  late RecurrenceType _recurrence;
  late List<int> _repeatWeekdays;
  late bool _isAppointment;
  AlertBefore? _alertBefore;
  String? _budgetCategory;
  bool _enableBudget = false;
  bool _enablePenalty = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _titleController.text = e?.title ?? '';
    _category = e?.category ?? TaskCategory.work;
    _dateTime = e?.dateTime ?? DateTime.now();
    _priority = e?.priority ?? TaskPriority.medium;
    _recurrence = e?.recurrence ?? RecurrenceType.none;
    _repeatWeekdays = e?.repeatWeekdays ?? [];
    if (_recurrence == RecurrenceType.daily && _repeatWeekdays.isEmpty) {
      _repeatWeekdays = List.from(allWeekdays);
    }
    _isAppointment = e?.isAppointment ?? false;
    _alertBefore = e?.alertBefore;
    _enableBudget = e?.budgetAmount != null;
    _enablePenalty = e?.penaltyAmount != null;
    _budgetController.text = e?.budgetAmount?.toString() ?? '';
    _penaltyController.text = e?.penaltyAmount?.toString() ?? '';
    _penaltyNotesController.text = e?.penaltyNotes ?? '';
    _budgetCategory = e?.budgetCategory ?? ExpenseCategory.transport.name;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _budgetController.dispose();
    _penaltyController.dispose();
    _penaltyNotesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currency = context.watch<AppProvider>().selectedCurrency;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing == null ? 'إضافة مهمة/موعد' : 'تعديل'),
        actions: widget.existing != null
            ? [
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: AppColors.expenseRed),
                  onPressed: _delete,
                ),
              ]
            : null,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('موعد (لقاء، حجز، إلخ)'),
              value: _isAppointment,
              activeColor: AppColors.neonBlue,
              onChanged: (v) => setState(() => _isAppointment = v),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: _isAppointment ? 'عنوان الموعد' : 'عنوان المهمة',
                prefixIcon: Icon(_isAppointment ? Icons.event : Icons.task),
              ),
              validator: (v) =>
                  v == null || v.isEmpty ? 'أدخل العنوان' : null,
            ),
            const SizedBox(height: 16),
            if (!_isAppointment)
              DropdownButtonFormField<TaskCategory>(
                value: _category,
                decoration: const InputDecoration(labelText: 'الفئة'),
                dropdownColor: AppColors.cardBlue,
                items: TaskCategory.values
                    .map((c) => DropdownMenuItem(
                          value: c,
                          child: Text(taskCategoryLabel(c)),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _category = v!),
              ),
            if (!_isAppointment) const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('التاريخ والوقت'),
              subtitle: Text(
                '${_dateTime.day}/${_dateTime.month}/${_dateTime.year} - ${_dateTime.hour}:${_dateTime.minute.toString().padLeft(2, '0')}',
                style: const TextStyle(color: AppColors.neonBlue),
              ),
              trailing: const Icon(Icons.access_time, color: AppColors.neonBlue),
              onTap: _pickDateTime,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<TaskPriority>(
              value: _priority,
              decoration: const InputDecoration(labelText: 'الأولوية'),
              dropdownColor: AppColors.cardBlue,
              items: TaskPriority.values
                  .map((p) => DropdownMenuItem(
                        value: p,
                        child: Text(priorityLabel(p)),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _priority = v!),
            ),
            const SizedBox(height: 16),
            RecurrencePicker(
              recurrence: _recurrence,
              selectedDays: _repeatWeekdays,
              onRecurrenceChanged: (r) => setState(() => _recurrence = r),
              onDaysChanged: (days) => setState(() => _repeatWeekdays = days),
            ),
            if (_isAppointment) ...[
              const SizedBox(height: 16),
              DropdownButtonFormField<AlertBefore>(
                value: _alertBefore,
                decoration: const InputDecoration(
                  labelText: 'تنبيه قبل',
                  prefixIcon: Icon(Icons.notifications),
                ),
                dropdownColor: AppColors.cardBlue,
                items: AlertBefore.values
                    .map((a) => DropdownMenuItem(
                          value: a,
                          child: Text(alertBeforeLabel(a)),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _alertBefore = v),
              ),
            ],
            const SizedBox(height: 24),
            _buildFinancialSection(currency),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.neonBlue,
                foregroundColor: AppColors.darkBlue,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                widget.existing == null ? 'حفظ' : 'تحديث',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialSection(AppCurrency currency) {
    return NeonCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.link, color: AppColors.neonBlue, size: 20),
              SizedBox(width: 8),
              Text(
                'الربط المالي (متقدم)',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('تخصيص ميزانية'),
            subtitle: Text(
              'مثال: الذهاب للنادي = 50 ${currency.symbol} مواصلات',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
            ),
            value: _enableBudget,
            activeColor: AppColors.neonBlue,
            onChanged: (v) => setState(() => _enableBudget = v),
          ),
          if (_enableBudget) ...[
            TextFormField(
              controller: _budgetController,
              decoration: InputDecoration(
                labelText: 'مبلغ الميزانية (${currency.symbol})',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _budgetCategory,
              decoration: const InputDecoration(labelText: 'فئة المصروف'),
              dropdownColor: AppColors.cardBlue,
              items: expenseCategories
                  .map((c) => DropdownMenuItem(
                        value: c,
                        child: Text(categoryLabel(c)),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _budgetCategory = v),
            ),
          ],
          const Divider(color: AppColors.divider),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('غرامة عند عدم الإنجاز'),
            subtitle: const Text(
              'تذكير مزدوج: مهمة غير منجزة = غرامة مالية',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
            ),
            value: _enablePenalty,
            activeColor: AppColors.expenseRed,
            onChanged: (v) => setState(() => _enablePenalty = v),
          ),
          if (_enablePenalty) ...[
            TextFormField(
              controller: _penaltyController,
              decoration: InputDecoration(
                labelText: 'مبلغ الغرامة (${currency.symbol})',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _penaltyNotesController,
              decoration: const InputDecoration(
                labelText: 'سبب الغرامة (مثال: تأخير سداد قسط)',
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dateTime,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.neonBlue,
              surface: AppColors.cardBlue,
            ),
          ),
          child: child!,
        );
      },
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dateTime),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.neonBlue,
              surface: AppColors.cardBlue,
            ),
          ),
          child: child!,
        );
      },
    );
    if (time == null || !mounted) return;

    setState(() {
      _dateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_recurrence == RecurrenceType.specificDays && _repeatWeekdays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اختر يوماً واحداً على الأقل للتكرار')),
      );
      return;
    }

    final provider = context.read<AppProvider>();
    final weekdays = _recurrence == RecurrenceType.daily
        ? List<int>.from(allWeekdays)
        : List<int>.from(_repeatWeekdays);

    final task = TaskItem(
      id: widget.existing?.id ?? provider.generateId(),
      title: _titleController.text,
      category: _category,
      dateTime: _dateTime,
      priority: _priority,
      recurrence: _recurrence,
      repeatWeekdays: weekdays,
      lastCompletedDate: widget.existing?.lastCompletedDate,
      isCompleted: widget.existing?.isCompleted ?? false,
      isAppointment: _isAppointment,
      alertBefore: _isAppointment ? _alertBefore : null,
      budgetAmount: _enableBudget && _budgetController.text.isNotEmpty
          ? double.tryParse(_budgetController.text)
          : null,
      budgetCategory: _enableBudget ? _budgetCategory : null,
      penaltyAmount: _enablePenalty && _penaltyController.text.isNotEmpty
          ? double.tryParse(_penaltyController.text)
          : null,
      penaltyNotes: _enablePenalty && _penaltyNotesController.text.isNotEmpty
          ? _penaltyNotesController.text
          : null,
    );

    if (widget.existing == null) {
      await provider.addTask(task);
    } else {
      await provider.updateTask(task);
    }

    if (mounted) Navigator.pop(context);
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBlue,
        title: const Text('حذف'),
        content: const Text('هل أنت متأكد؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف', style: TextStyle(color: AppColors.expenseRed)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await context.read<AppProvider>().deleteTask(widget.existing!.id);
      if (mounted) Navigator.pop(context);
    }
  }
}
