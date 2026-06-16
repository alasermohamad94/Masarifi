class AppCurrency {
  final String code;
  final String symbol;
  final String nameAr;
  final String nameEn;

  const AppCurrency({
    required this.code,
    required this.symbol,
    required this.nameAr,
    required this.nameEn,
  });

  static const sar = AppCurrency(
    code: 'SAR',
    symbol: 'ر.س',
    nameAr: 'ريال سعودي',
    nameEn: 'Saudi Riyal',
  );

  static const usd = AppCurrency(
    code: 'USD',
    symbol: '\$',
    nameAr: 'دولار أمريكي',
    nameEn: 'US Dollar',
  );

  static const syp = AppCurrency(
    code: 'SYP',
    symbol: 'ل.س',
    nameAr: 'ليرة سورية',
    nameEn: 'Syrian Pound',
  );

  static const try_ = AppCurrency(
    code: 'TRY',
    symbol: '₺',
    nameAr: 'ليرة تركية',
    nameEn: 'Turkish Lira',
  );

  static const eur = AppCurrency(
    code: 'EUR',
    symbol: '€',
    nameAr: 'يورو',
    nameEn: 'Euro',
  );

  static const gbp = AppCurrency(
    code: 'GBP',
    symbol: '£',
    nameAr: 'جنيه إسترليني',
    nameEn: 'British Pound',
  );

  static const aed = AppCurrency(
    code: 'AED',
    symbol: 'د.إ',
    nameAr: 'درهم إماراتي',
    nameEn: 'UAE Dirham',
  );

  static const egp = AppCurrency(
    code: 'EGP',
    symbol: 'ج.م',
    nameAr: 'جنيه مصري',
    nameEn: 'Egyptian Pound',
  );

  static const jod = AppCurrency(
    code: 'JOD',
    symbol: 'د.أ',
    nameAr: 'دينار أردني',
    nameEn: 'Jordanian Dinar',
  );

  static const kwd = AppCurrency(
    code: 'KWD',
    symbol: 'د.ك',
    nameAr: 'دينار كويتي',
    nameEn: 'Kuwaiti Dinar',
  );

  static const iqd = AppCurrency(
    code: 'IQD',
    symbol: 'د.ع',
    nameAr: 'دينار عراقي',
    nameEn: 'Iraqi Dinar',
  );

  static const lbp = AppCurrency(
    code: 'LBP',
    symbol: 'ل.ل',
    nameAr: 'ليرة لبنانية',
    nameEn: 'Lebanese Pound',
  );

  static const all = [sar, usd, syp, try_, eur, gbp, aed, egp, jod, kwd, iqd, lbp];

  static AppCurrency fromCode(String code) {
    return all.firstWhere(
      (c) => c.code == code,
      orElse: () => sar,
    );
  }
}
