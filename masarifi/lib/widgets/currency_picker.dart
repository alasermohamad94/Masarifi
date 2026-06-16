import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../models/currency.dart';
import '../providers/app_provider.dart';

class CurrencyPickerButton extends StatelessWidget {
  const CurrencyPickerButton({super.key});

  @override
  Widget build(BuildContext context) {
    final currency = context.watch<AppProvider>().selectedCurrency;

    return GestureDetector(
      onTap: () => _showPicker(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.neonBlue.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.neonBlue.withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.currency_exchange, size: 16, color: AppColors.neonBlue),
            const SizedBox(width: 4),
            Text(
              currency.symbol,
              style: const TextStyle(
                color: AppColors.neonBlue,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.navyBlue,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'اختر العملة',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: AppCurrency.all.length,
                  itemBuilder: (context, index) {
                    final currency = AppCurrency.all[index];
                    final selected =
                        context.watch<AppProvider>().selectedCurrency.code ==
                            currency.code;

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: selected
                            ? AppColors.neonBlue.withValues(alpha: 0.2)
                            : AppColors.cardBlue,
                        child: Text(
                          currency.symbol,
                          style: TextStyle(
                            color: selected
                                ? AppColors.neonBlue
                                : AppColors.textSecondary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      title: Text(
                        currency.nameAr,
                        style: TextStyle(
                          color: selected
                              ? AppColors.neonBlue
                              : AppColors.textPrimary,
                          fontWeight:
                              selected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      subtitle: Text(
                        currency.code,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      trailing: selected
                          ? const Icon(Icons.check_circle, color: AppColors.neonBlue)
                          : null,
                      onTap: () {
                        context.read<AppProvider>().setCurrency(currency);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
