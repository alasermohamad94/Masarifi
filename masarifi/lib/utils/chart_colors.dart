import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

/// ألوان موحّدة للرسوم البيانية والفئات
class ChartColors {
  ChartColors._();

  static const palette = [
    Color(0xFF00E5FF), // نيون أزرق
    Color(0xFF7B61FF), // بنفسجي
    Color(0xFFFF6B9D), // وردي
    Color(0xFFE8B86D), // برتقالي هادئ
    Color(0xFF8FBDB2), // أخضر مسطح
    Color(0xFFBDACAC), // أحمر مسطح
    Color(0xFF48CAE4), // سماوي
    Color(0xFFBF5AF2), // بنفسجي فاتح
    Color(0xFFFFD60A), // أصفر
    Color(0xFF64D2FF), // أزرق فاتح
    Color(0xFF30D158), // أخضر Apple
    Color(0xFFFF9F0A), // برتقالي داكن
  ];

  static const categoryMap = {
    'food': Color(0xFFFFAB40),
    'transport': Color(0xFF00E5FF),
    'rent': Color(0xFF7B61FF),
    'utilities': Color(0xFFFFD60A),
    'entertainment': Color(0xFFFF6B9D),
    'health': Color(0xFF8FBDB2),
    'shopping': Color(0xFF48CAE4),
    'other': Color(0xFF94A3B8),
    'salary': Color(0xFF8FBDB2),
    'freelance': Color(0xFF64D2FF),
    'investment': Color(0xFFBF5AF2),
    'gift': Color(0xFFFF6B9D),
  };

  static Color forCategory(String category, [int fallbackIndex = 0]) {
    return categoryMap[category] ?? palette[fallbackIndex % palette.length];
  }

  static Color forIndex(int index) => palette[index % palette.length];

  static LinearGradient gradientFor(Color color) {
    return LinearGradient(
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
      colors: [
        color.withValues(alpha: 0.6),
        color,
      ],
    );
  }

  static LinearGradient gradientForIndex(int index) =>
      gradientFor(forIndex(index));
}

/// ألوان بطاقات الديون
class DebtColors {
  DebtColors._();

  static const owedByMe = AppColors.expenseRed;
  static const owedToMe = AppColors.incomeGreen;

  static Color cardBackground(bool isOwedByMe) {
    final base = isOwedByMe ? owedByMe : owedToMe;
    return AppColors.cardSurface(base);
  }

  static Color borderColor(bool isOwedByMe) =>
      AppColors.cardBorder(isOwedByMe ? owedByMe : owedToMe);

  static Color accentColor(bool isOwedByMe) =>
      isOwedByMe ? owedByMe : owedToMe;
}
