import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../widgets/common_widgets.dart';

/// عدّل بيانات المطوّر وطرق التواصل من هنا.
/// ضع صورتك في: assets/images/developer.jpg
class DeveloperInfo {
  DeveloperInfo._();

  static const name = 'المهندس محمد أحمد حمدان';
  static const role = 'تصميم وبرمجة';
  static const appName = 'مصاريفي';
  static const appDescription =
      'تطبيق عربي لإدارة الدخل والمصروفات والديون والمهام والمواعيد بشكل شخصي وسهل.';
  static const photoPath = 'assets/images/developer.jpg';

  static const phone = '';
  static const email = 'alasermohamad94@gmail.com';
  static const whatsapp = '+963967770101';
  static const telegram = '@Eng_MAH94';
  static const website = '';
}

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final contacts = _contactItems();

    return Scaffold(
      appBar: AppBar(
        title: const Text('عن التطبيق'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          NeonCard(
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
            child: Column(
              children: [
                _DeveloperPhoto(),
                const SizedBox(height: 20),
                Text(
                  DeveloperInfo.appName,
                  style: const TextStyle(
                    color: AppColors.neonBlue,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                Text(
                  DeveloperInfo.role,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  DeveloperInfo.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  DeveloperInfo.appDescription,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
          if (contacts.isNotEmpty) ...[
            const SizedBox(height: 20),
            const SectionHeader(title: 'طرق التواصل'),
            ...contacts.map((item) => _ContactTile(item: item)),
          ],
          const SizedBox(height: 24),
          const Center(
            child: Text(
              '© جميع الحقوق محفوظة',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  List<_ContactItem> _contactItems() {
    final items = <_ContactItem>[];

    void add(String value, IconData icon, String label, Color color) {
      if (value.trim().isNotEmpty) {
        items.add(_ContactItem(icon: icon, label: label, value: value.trim(), color: color));
      }
    }

    add(DeveloperInfo.phone, Icons.phone, 'هاتف', AppColors.neonBlue);
    add(DeveloperInfo.email, Icons.email_outlined, 'بريد إلكتروني', AppColors.accentPurple);
    add(DeveloperInfo.whatsapp, Icons.chat, 'واتساب', AppColors.incomeGreen);
    add(DeveloperInfo.telegram, Icons.send, 'تيليجرام', AppColors.neonBlueDim);
    add(DeveloperInfo.website, Icons.language, 'موقع إلكتروني', AppColors.warningOrange);

    return items;
  }
}

class _DeveloperPhoto extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.neonBlue.withValues(alpha: 0.5), width: 3),
        boxShadow: [
          BoxShadow(
            color: AppColors.neonBlue.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          DeveloperInfo.photoPath,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: AppColors.navyBlue,
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.engineering, color: AppColors.neonBlue, size: 48),
                SizedBox(height: 4),
                Text(
                  'م.ح',
                  style: TextStyle(
                    color: AppColors.neonBlue,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ContactItem {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _ContactItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
}

class _ContactTile extends StatelessWidget {
  final _ContactItem item;

  const _ContactTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return NeonCard(
      accentColor: item.color,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.iconBackground(item.color),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cardBorder(item.color)),
            ),
            child: Icon(item.icon, color: item.color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                SelectableText(
                  item.value,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
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
