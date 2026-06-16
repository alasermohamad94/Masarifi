import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/task.dart';
import 'common_widgets.dart';

class RecurrencePicker extends StatelessWidget {
  final RecurrenceType recurrence;
  final List<int> selectedDays;
  final ValueChanged<RecurrenceType> onRecurrenceChanged;
  final ValueChanged<List<int>> onDaysChanged;

  const RecurrencePicker({
    super.key,
    required this.recurrence,
    required this.selectedDays,
    required this.onRecurrenceChanged,
    required this.onDaysChanged,
  });

  @override
  Widget build(BuildContext context) {
    return NeonCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.repeat, color: AppColors.neonBlue, size: 20),
              SizedBox(width: 8),
              Text(
                'التكرار',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _RecurrenceChip(
                label: 'بدون',
                selected: recurrence == RecurrenceType.none,
                onTap: () {
                  onRecurrenceChanged(RecurrenceType.none);
                  onDaysChanged([]);
                },
              ),
              _RecurrenceChip(
                label: 'كل يوم',
                selected: recurrence == RecurrenceType.daily,
                onTap: () {
                  onRecurrenceChanged(RecurrenceType.daily);
                  onDaysChanged(List.from(allWeekdays));
                },
              ),
              _RecurrenceChip(
                label: 'أيام محددة',
                selected: recurrence == RecurrenceType.specificDays,
                onTap: () {
                  onRecurrenceChanged(RecurrenceType.specificDays);
                  if (selectedDays.isEmpty) {
                    onDaysChanged([DateTime.now().weekday]);
                  }
                },
              ),
            ],
          ),
          if (recurrence == RecurrenceType.specificDays) ...[
            const SizedBox(height: 16),
            const Text(
              'اختر الأيام',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: allWeekdays.map((day) {
                final selected = selectedDays.contains(day);
                return GestureDetector(
                  onTap: () {
                    final updated = List<int>.from(selectedDays);
                    if (selected) {
                      updated.remove(day);
                    } else {
                      updated.add(day);
                    }
                    updated.sort();
                    onDaysChanged(updated);
                  },
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.neonBlue.withValues(alpha: 0.25)
                          : AppColors.navyBlue,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected
                            ? AppColors.neonBlue
                            : AppColors.divider,
                        width: selected ? 2 : 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        weekdayLabels[day] ?? '',
                        style: TextStyle(
                          color: selected
                              ? AppColors.neonBlue
                              : AppColors.textSecondary,
                          fontWeight:
                              selected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            if (selectedDays.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'اختر يوماً واحداً على الأقل',
                  style: TextStyle(color: AppColors.expenseRed, fontSize: 12),
                ),
              ),
          ],
          if (recurrence != RecurrenceType.none) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.neonBlue.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.neonBlue.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
                      size: 16, color: AppColors.neonBlue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      recurrence == RecurrenceType.daily
                          ? 'تظهر كل يوم من تاريخ البداية'
                          : 'تظهر: ${recurrenceLabel(recurrence, selectedDays)}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RecurrenceChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _RecurrenceChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.neonBlue.withValues(alpha: 0.2)
              : AppColors.navyBlue,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.neonBlue : AppColors.divider,
            width: selected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.neonBlue : AppColors.textSecondary,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
