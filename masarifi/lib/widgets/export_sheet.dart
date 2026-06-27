import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../providers/app_provider.dart';
import '../services/export_service.dart';

Future<void> showExportSheet(
  BuildContext context, {
  ExportScope scope = ExportScope.full,
}) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.navyBlue,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      final title = ExportService.scopeTitle(scope);
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'مشاركة $title',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'شارك كنص أو ملف CSV عبر واتساب أو Google Drive',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 20),
              _ExportOption(
                icon: Icons.chat,
                color: const Color(0xFF25D366),
                title: 'واتساب',
                subtitle: 'إرسال التقرير كنص',
                onTap: () async {
                  Navigator.pop(ctx);
                  final p = context.read<AppProvider>();
                  await ExportService.shareWhatsApp(
                    ExportService.buildReport(
                      scope: scope,
                      transactions: p.transactions,
                      debts: p.debts,
                      tasks: p.tasks,
                      currency: p.selectedCurrency,
                      formatMoney: p.formatMoney,
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
              _ExportOption(
                icon: Icons.cloud_upload,
                color: AppColors.neonBlue,
                title: 'Google Drive / ملف CSV',
                subtitle: 'تصدير ملف واختيار Drive من المشاركة',
                onTap: () async {
                  Navigator.pop(ctx);
                  final p = context.read<AppProvider>();
                  await ExportService.shareCsv(
                    content: ExportService.buildCsv(
                      scope: scope,
                      transactions: p.transactions,
                      debts: p.debts,
                      tasks: p.tasks,
                      currency: p.selectedCurrency,
                    ),
                    fileName: ExportService.csvFileName(scope),
                  );
                },
              ),
              const SizedBox(height: 10),
              _ExportOption(
                icon: Icons.share,
                color: AppColors.accentPurple,
                title: 'مشاركة عامة',
                subtitle: 'إرسال عبر أي تطبيق',
                onTap: () async {
                  Navigator.pop(ctx);
                  final p = context.read<AppProvider>();
                  await ExportService.shareReport(
                    scope: scope,
                    transactions: p.transactions,
                    debts: p.debts,
                    tasks: p.tasks,
                    currency: p.selectedCurrency,
                    formatMoney: p.formatMoney,
                    asCsv: false,
                  );
                },
              ),
              if (scope == ExportScope.full) ...[
                const SizedBox(height: 16),
                const Divider(color: AppColors.divider),
                const SizedBox(height: 8),
                const Text(
                  'مشاركة قسم محدد',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _ScopeChip(
                      label: 'مصروفات',
                      color: AppColors.expenseRed,
                      onTap: () {
                        Navigator.pop(ctx);
                        showExportSheet(context, scope: ExportScope.expenses);
                      },
                    ),
                    _ScopeChip(
                      label: 'ديون',
                      color: AppColors.expenseRed,
                      onTap: () {
                        Navigator.pop(ctx);
                        showExportSheet(context, scope: ExportScope.debts);
                      },
                    ),
                    _ScopeChip(
                      label: 'مواعيد',
                      color: AppColors.accentPurple,
                      onTap: () {
                        Navigator.pop(ctx);
                        showExportSheet(context,
                            scope: ExportScope.appointments);
                      },
                    ),
                    _ScopeChip(
                      label: 'مهام',
                      color: AppColors.neonBlue,
                      onTap: () {
                        Navigator.pop(ctx);
                        showExportSheet(context, scope: ExportScope.tasks);
                      },
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      );
    },
  );
}

class _ScopeChip extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ScopeChip({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      backgroundColor: color.withValues(alpha: 0.15),
      labelStyle: TextStyle(color: color, fontWeight: FontWeight.w600),
      side: BorderSide(color: color.withValues(alpha: 0.4)),
      onPressed: onTap,
    );
  }
}

class _ExportOption extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ExportOption({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.cardBlue,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
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
              const Icon(Icons.chevron_left, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
