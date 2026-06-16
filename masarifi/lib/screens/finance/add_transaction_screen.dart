import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/transaction.dart';
import '../../providers/app_provider.dart';

const _addNewCategoryValue = '__add_new__';

class AddTransactionScreen extends StatefulWidget {
  final FinancialTransaction? existing;

  const AddTransactionScreen({super.key, this.existing});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  late TransactionType _type;
  late String _category;
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  late DateTime _date;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _type = e?.type ?? TransactionType.expense;
    _category = e?.category ?? ExpenseCategory.food.name;
    _amountController.text = e?.amount.toString() ?? '';
    _notesController.text = e?.notes ?? '';
    _date = e?.date ?? DateTime.now();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  List<String> _categories(AppProvider provider) {
    final list = provider.categoriesFor(_type);
    if (!list.contains(_category) &&
        _category.isNotEmpty &&
        _category != _addNewCategoryValue) {
      return [...list, _category];
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final currency = provider.selectedCurrency;
    final categories = _categories(provider);
    final dropdownValue =
        categories.contains(_category) ? _category : categories.first;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing == null ? 'إضافة حركة مالية' : 'تعديل حركة'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('النوع', style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _TypeButton(
                    label: 'دخل',
                    icon: Icons.arrow_downward,
                    color: AppColors.incomeGreen,
                    selected: _type == TransactionType.income,
                    onTap: () => setState(() {
                      _type = TransactionType.income;
                      _category = IncomeCategory.salary.name;
                    }),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _TypeButton(
                    label: 'مصروف',
                    icon: Icons.arrow_upward,
                    color: AppColors.expenseRed,
                    selected: _type == TransactionType.expense,
                    onTap: () => setState(() {
                      _type = TransactionType.expense;
                      _category = ExpenseCategory.food.name;
                    }),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: dropdownValue,
              decoration: const InputDecoration(labelText: 'الفئة'),
              dropdownColor: AppColors.cardBlue,
              items: [
                ...categories.map(
                  (c) => DropdownMenuItem(
                    value: c,
                    child: Row(
                      children: [
                        if (!provider.isBuiltInCategory(c))
                          const Padding(
                            padding: EdgeInsets.only(left: 4),
                            child: Icon(
                              Icons.label_outline,
                              size: 16,
                              color: AppColors.neonBlue,
                            ),
                          ),
                        Text(categoryLabel(c)),
                      ],
                    ),
                  ),
                ),
                const DropdownMenuItem(
                  value: _addNewCategoryValue,
                  child: Row(
                    children: [
                      Icon(Icons.add_circle_outline,
                          size: 18, color: AppColors.neonBlue),
                      SizedBox(width: 8),
                      Text(
                        'إضافة فئة جديدة...',
                        style: TextStyle(color: AppColors.neonBlue),
                      ),
                    ],
                  ),
                ),
              ],
              onChanged: (v) async {
                if (v == _addNewCategoryValue) {
                  await _showAddCategoryDialog(provider);
                } else if (v != null) {
                  setState(() => _category = v);
                }
              },
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
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('التاريخ'),
              subtitle: Text(
                '${_date.day}/${_date.month}/${_date.year}',
                style: const TextStyle(color: AppColors.neonBlue),
              ),
              trailing: const Icon(Icons.calendar_today, color: AppColors.neonBlue),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(2020),
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
                if (picked != null) setState(() => _date = picked);
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'ملاحظات (اختياري)',
                prefixIcon: Icon(Icons.notes),
              ),
              maxLines: 3,
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
                widget.existing == null ? 'حفظ الحركة' : 'تحديث',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddCategoryDialog(AppProvider provider) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBlue,
        title: const Text('فئة جديدة'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            labelText: _type == TransactionType.income
                ? 'اسم فئة الدخل'
                : 'اسم فئة المصروف',
            hintText: 'مثال: تعليم، صيانة...',
          ),
          textCapitalization: TextCapitalization.sentences,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isEmpty) return;
              Navigator.pop(ctx, name);
            },
            child: const Text('إضافة', style: TextStyle(color: AppColors.neonBlue)),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty && mounted) {
      await provider.addCustomCategory(_type, result);
      setState(() => _category = result);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<AppProvider>();
    final transaction = FinancialTransaction(
      id: widget.existing?.id ?? provider.generateId(),
      type: _type,
      category: _category,
      amount: double.parse(_amountController.text),
      date: _date,
      notes: _notesController.text.isEmpty ? null : _notesController.text,
    );

    if (widget.existing == null) {
      await provider.addTransaction(transaction);
    } else {
      await provider.updateTransaction(transaction);
    }

    if (mounted) Navigator.pop(context);
  }
}

class _TypeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _TypeButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.softFill(color)
              : AppColors.navyBlue,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.cardBorder(color) : AppColors.divider,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: selected ? color : AppColors.textSecondary),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: selected ? color : AppColors.textSecondary,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
