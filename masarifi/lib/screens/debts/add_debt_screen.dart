import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/debt.dart';
import '../../providers/app_provider.dart';

class AddDebtScreen extends StatefulWidget {
  final Debt? existing;
  final DebtDirection? initialDirection;

  const AddDebtScreen({super.key, this.existing, this.initialDirection});

  @override
  State<AddDebtScreen> createState() => _AddDebtScreenState();
}

class _AddDebtScreenState extends State<AddDebtScreen> {
  final _formKey = GlobalKey<FormState>();
  late DebtDirection _direction;
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _paidController = TextEditingController();
  final _notesController = TextEditingController();
  late DateTime _dueDate;
  late DebtStatus _status;
  bool _reminderEnabled = true;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _direction = e?.direction ?? widget.initialDirection ?? DebtDirection.owedByMe;
    _nameController.text = e?.personName ?? '';
    _amountController.text = e?.totalAmount.toString() ?? '';
    _paidController.text = e?.paidAmount.toString() ?? '0';
    _notesController.text = e?.notes ?? '';
    _dueDate = e?.dueDate ?? DateTime.now().add(const Duration(days: 30));
    _status = e?.status ?? DebtStatus.pending;
    _reminderEnabled = e?.reminderEnabled ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _paidController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currency = context.watch<AppProvider>().selectedCurrency;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing == null ? 'إضافة دين' : 'تعديل دين'),
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
            const Text('نوع الدين', style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _DirectionChip(
                    label: 'ديون عليّ',
                    selected: _direction == DebtDirection.owedByMe,
                    accentColor: AppColors.expenseRed,
                    onTap: () => setState(() => _direction = DebtDirection.owedByMe),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DirectionChip(
                    label: 'ديون لي',
                    selected: _direction == DebtDirection.owedToMe,
                    accentColor: AppColors.incomeGreen,
                    onTap: () => setState(() => _direction = DebtDirection.owedToMe),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: _direction == DebtDirection.owedByMe
                    ? 'اسم الدائن'
                    : 'اسم المدين',
                prefixIcon: const Icon(Icons.person),
              ),
              validator: (v) =>
                  v == null || v.isEmpty ? 'أدخل الاسم' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              decoration: InputDecoration(
                labelText: 'المبلغ (${currency.symbol})',
                prefixIcon: const Icon(Icons.attach_money),
              ),
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v == null || v.isEmpty) return 'أدخل المبلغ';
                if (double.tryParse(v) == null) return 'مبلغ غير صالح';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _paidController,
              decoration: InputDecoration(
                labelText: 'المبلغ المدفوع (${currency.symbol})',
                prefixIcon: const Icon(Icons.payments),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<DebtStatus>(
              value: _status,
              decoration: const InputDecoration(labelText: 'الحالة'),
              dropdownColor: AppColors.cardBlue,
              items: DebtStatus.values
                  .map((s) => DropdownMenuItem(
                        value: s,
                        child: Text(debtStatusLabel(s)),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _status = v!),
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(_direction == DebtDirection.owedByMe
                  ? 'تاريخ السداد المتوقع'
                  : 'تاريخ الاستحقاق'),
              subtitle: Text(
                '${_dueDate.day}/${_dueDate.month}/${_dueDate.year}',
                style: const TextStyle(color: AppColors.neonBlue),
              ),
              trailing: const Icon(Icons.calendar_today, color: AppColors.neonBlue),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _dueDate,
                  firstDate: DateTime.now(),
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
                if (picked != null) setState(() => _dueDate = picked);
              },
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('تذكير بالموعد'),
              subtitle: const Text(
                'تنبيه قبل 3 أيام من الاستحقاق',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              value: _reminderEnabled,
              activeColor: AppColors.neonBlue,
              onChanged: (v) => setState(() => _reminderEnabled = v),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'ملاحظات',
                prefixIcon: Icon(Icons.notes),
              ),
              maxLines: 2,
            ),
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<AppProvider>();
    final paid = double.tryParse(_paidController.text) ?? 0;

    final debt = Debt(
      id: widget.existing?.id ?? provider.generateId(),
      direction: _direction,
      personName: _nameController.text,
      totalAmount: double.parse(_amountController.text),
      paidAmount: paid,
      dueDate: _dueDate,
      status: _status,
      notes: _notesController.text.isEmpty ? null : _notesController.text,
      reminderEnabled: _reminderEnabled,
    );

    if (widget.existing == null) {
      await provider.addDebt(debt);
    } else {
      await provider.updateDebt(debt);
    }

    if (mounted) Navigator.pop(context);
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBlue,
        title: const Text('حذف الدين'),
        content: const Text('هل أنت متأكد من حذف هذا الدين؟'),
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
      await context.read<AppProvider>().deleteDebt(widget.existing!.id);
      if (mounted) Navigator.pop(context);
    }
  }
}

class _DirectionChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color accentColor;
  final VoidCallback onTap;

  const _DirectionChip({
    required this.label,
    required this.selected,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? accentColor.withValues(alpha: 0.2)
              : AppColors.navyBlue,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? accentColor : AppColors.divider,
            width: selected ? 2 : 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: selected ? accentColor : AppColors.textSecondary,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
