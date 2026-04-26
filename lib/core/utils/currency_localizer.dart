/// Maps stored currency codes to their localized display symbols.
///
/// The app stores the raw code chosen during onboarding (e.g. "TND", "MAD").
/// In Arabic UI the script symbol looks much better than the Latin code.
/// For EN / FR the Latin code / symbol is kept as-is.
class CurrencyLocalizer {
  CurrencyLocalizer._();

  /// Arabic-script equivalents for common currency codes.
  static const Map<String, String> _arabicSymbols = {
    'TND': 'د.ت',   // Tunisian Dinar
    'DZD': 'د.ج',   // Algerian Dinar
    'DA':  'د.ج',   // Algerian Dinar (alternate code)
    'MAD': 'د.م.',  // Moroccan Dirham
    'SAR': 'ر.س',   // Saudi Riyal
    'AED': 'د.إ',   // UAE Dirham
    'KWD': 'د.ك',   // Kuwaiti Dinar
    'BHD': 'د.ب',   // Bahraini Dinar
    'OMR': 'ر.ع.',  // Omani Rial
    'QAR': 'ر.ق',   // Qatari Riyal
    'JOD': 'د.أ',   // Jordanian Dinar
    'LYD': 'د.ل',   // Libyan Dinar
    'IQD': 'د.ع',   // Iraqi Dinar
    'EGP': 'ج.م',   // Egyptian Pound
    'LBP': 'ل.ل',   // Lebanese Pound
    'SYP': 'ل.س',   // Syrian Pound
    'YER': 'ر.ي',   // Yemeni Rial
    'SDG': 'ج.س',   // Sudanese Pound
    'MRU': 'أ.م',   // Mauritanian Ouguiya
  };

  /// Returns the display symbol for [code] in the given [language].
  ///
  /// - Arabic → Arabic-script symbol when available, otherwise returns [code] as-is.
  /// - EN / FR → returns [code] as-is (already a symbol like "$", "€" or a code like "TND").
  static String localize(String code, String language) {
    if (language == 'ar') {
      return _arabicSymbols[code.toUpperCase()] ?? code;
    }
    return code;
  }
}
